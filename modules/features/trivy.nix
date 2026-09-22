_: {
  flake.modules.nixos.trivy = {
    config,
    pkgs,
    ...
  }: {
    systemd.services.trivy-image-scan = {
      description = "Daily container image CVE scan";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "trivy";
        ExecStart = pkgs.writeShellScript "trivy-image-scan" ''
          set -u
          export TRIVY_CACHE_DIR=/var/lib/trivy
          tars="$TRIVY_CACHE_DIR/tars"
          rpt="$TRIVY_CACHE_DIR/report.json"
          report="$TRIVY_CACHE_DIR/report.txt"
          mkdir -p "$tars"
          : > "$report"
          crit_total=0
          high_total=0
          med_total=0
          low_total=0
          img_found=0
          errors=0

          emit_line() {
            local sev=$1 list=$2
            if [ -z "$list" ]; then
              return
            fi
            n="$(${pkgs.gnugrep}/bin/grep -o ',' <<< "$list" | wc -l)"
            printf '%-8s %s: %s\n' "$sev" "$((n + 1))" "$list"
          }

          # $1: tool binary (podman|docker), $2: image ref
          scan_ref() {
            local tool=$1 img=$2
            case "$img" in
              ""|"<none>:*") return ;;
            esac
            if "$tool" save --format docker-archive "$img" > "$tars/cur.tar" 2>/dev/null; then
              echo "=== $img ==="
              if ! ${pkgs.trivy}/bin/trivy image \
                  --input "$tars/cur.tar" \
                  --scanners vuln \
                  --ignore-unfixed \
                  --exit-code 1 \
                  --quiet \
                  --no-progress \
                  --format json \
                  --output "$rpt" 2>&1; then
                crit_count="$(${pkgs.jq}/bin/jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$rpt" 2>/dev/null || echo 0)"
                high_count="$(${pkgs.jq}/bin/jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$rpt" 2>/dev/null || echo 0)"
                med_count="$(${pkgs.jq}/bin/jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$rpt" 2>/dev/null || echo 0)"
                low_count="$(${pkgs.jq}/bin/jq -r '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' "$rpt" 2>/dev/null || echo 0)"
                if [ $((crit_count + high_count + med_count + low_count)) -gt 0 ]; then
                  img_found=$((img_found + 1))
                  crit_total=$((crit_total + crit_count))
                  high_total=$((high_total + high_count))
                  med_total=$((med_total + med_count))
                  low_total=$((low_total + low_count))
                  echo "=== $img ===" >> "$report"
                  for sev in CRITICAL HIGH MEDIUM LOW; do
                    list="$(${pkgs.jq}/bin/jq -r \
                      --arg s "$sev" \
                      '[.Results[]?.Vulnerabilities[]? | select(.Severity==$s) | .VulnerabilityID] | unique | join(", ")' \
                      "$rpt" 2>/dev/null)"
                    if [ -n "$list" ]; then
                      emit_line "$sev" "$list" >> "$report"
                    fi
                  done
                  echo "FOUND $(($crit_count + $high_count + $med_count + $low_count)) CVEs in $img"
                else
                  errors=1
                  echo "trivy scanner error (nonzero rc, empty findings json)"
                fi
              fi
              rm -f "$tars/cur.tar" "$rpt"
            fi
          }

          # Rootful podman store (subtrakr and anything else podman runs)
          while IFS= read -r img; do
            scan_ref ${pkgs.podman}/bin/podman "$img"
          done < <(${pkgs.podman}/bin/podman images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null)

          total=$((crit_total + high_total + med_total + low_total))
          {
            echo ""
            echo "TOTALS: $total CVEs across $img_found image(s) ($crit_total critical, $high_total high, $med_total medium, $low_total low)"
          } >> "$report"

          if [ $((crit_total + high_total)) -gt 0 ]; then
            webhook="$(cat ${config.sops.secrets."discord/ein-webhook".path})"
            payload_json="$(${pkgs.jq}/bin/jq -n \
              --arg t "**Trivy Image Scan**" \
              --arg c "$total CVEs across $img_found image(s)" \
              --arg e "🔴 $crit_total | 🟠 $high_total | 🟡 $med_total | 🟢 $low_total" \
              '{content: ($t + "\n" + $c + "\n" + $e)}')"
            ${pkgs.curl}/bin/curl -fsS -m 15 \
              -F "payload_json=$payload_json" \
              -F "file=@$report;filename=trivy-report.txt" \
              "$webhook" > /dev/null 2>&1 || true
            exit 1
          elif [ "$errors" -gt 0 ]; then
            exit 2
          fi
        '';
      };
    };

    systemd.timers.trivy-image-scan = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "trivy-image-scan.service";
      };
    };
  };
}
