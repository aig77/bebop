_: {
  flake.modules.nixos.vulnix = {
    config,
    pkgs,
    ...
  }: let
    # Whitelist, TOML format. Keyed by package ("pkg") or package-version
    # ("pkg-1.2.3"); the `.toml` extension is required so vulnix skips its
    # content heuristic. Silence verified false positives or
    # unfixable-at-the-pinned-version advisories only; re-check each entry
    # (nix shell nixpkgs#vulnix -- vulnix --system) before keeping it.
    #
    #   ["socat-1.7.4.4"]
    #   cve = ["CVE-2023-35788"]
    #   comment = "no upstream fix at pinned version"
    #
    # Or wildcard (must carry at least one cve): ["*"]
    whitelist = pkgs.writeText "vulnix.whitelist.toml" ''
      # Scope format: `CVE-YYYY-XXXX` or `package CVE-YYYY-XXXX`.
    '';
  in {
    sops.secrets."discord/ein-webhook" = {};

    systemd.services.vulnix-scan = {
      description = "Nightly Nix closure CVE scan";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "vulnix";
        Environment = "LANG=C.UTF-8";
        ExecStart = pkgs.writeShellScript "vulnix-scan" ''
          set -u
          state=/var/lib/vulnix
          report_json="$state/report.json"
          report_txt="$state/report.txt"
          error_log="$state/error.log"
          : > "$error_log"

          if ! ${pkgs.vulnix}/bin/vulnix \
              --system \
              --json \
              --cache-dir $state/nvd \
              --whitelist ${whitelist} > "$report_json" 2> "$error_log"; then
            status=$?
            if ${pkgs.gnugrep}/bin/grep -qiE 'traceback|runtimeerror|cannot detect|\bERROR\b' "$error_log"; then
              echo "vulnix scanner error (exit $status); see $state/error.log" >&2
              exit 2
            fi
          fi

          nd="$(${pkgs.jq}/bin/jq -r 'length' "$report_json" 2>/dev/null || echo 0)"
          if [ "$nd" -eq 0 ]; then
            rm -f "$state/vulns-found"
            exit 0
          fi

          ${pkgs.jq}/bin/jq -r '
            .[] as $d |
            "=== " + $d.name + " (" + $d.version + ") ===",
            def cnt($lo; $hi): [$d.affected_by[] | ($d.cvssv3_basescore[.] // 0) as $v | select($v >= $lo and $v < $hi)] | length;
            def lst($lo; $hi): [$d.affected_by[] | select(($d.cvssv3_basescore[.] // 0) >= $lo and ($d.cvssv3_basescore[.] // 0) < $hi)] | sort;
            if cnt(9; 100) > 0 then "CRITICAL " + (cnt(9; 100) | tostring) + ": " + (lst(9; 100) | join(", ")) else empty end,
            if cnt(7; 9) > 0 then "HIGH " + (cnt(7; 9) | tostring) + ": " + (lst(7; 9) | join(", ")) else empty end,
            if cnt(4; 7) > 0 then "MEDIUM " + (cnt(4; 7) | tostring) + ": " + (lst(4; 7) | join(", ")) else empty end,
            if cnt(1; 4) > 0 then "LOW " + (cnt(1; 4) | tostring) + ": " + (lst(1; 4) | join(", ")) else empty end,
            if cnt(0; 1) > 0 then "UNKNOWN " + (cnt(0; 1) | tostring) + ": " + (lst(0; 1) | join(", ")) else empty end,
            ""' "$report_json" > "$report_txt"

          bucket_tsv="$(${pkgs.jq}/bin/jq -r '[.[] as $d | $d.affected_by[] as $id | ($d.cvssv3_basescore[$id] // 0)] as $s | [
            ($s | map(select(. >= 9)) | length),
            ($s | map(select(. >= 7 and . < 9)) | length),
            ($s | map(select(. >= 4 and . < 7)) | length),
            ($s | map(select(. >= 1 and . < 4)) | length),
            ($s | map(select(. == 0)) | length)] | @tsv' "$report_json")"
          read -r crit high med low unk <<< "$bucket_tsv"
          total=$((crit + high + med + low + unk))

          {
            echo ""
            echo "TOTALS: $total CVEs across $nd derivation(s) ($crit critical, $high high, $med medium, $low low, $unk unknown)"
          } >> "$report_txt"

          if [ $((crit + high)) -le 0 ]; then
            rm -f "$state/vulns-found"
            exit 0
          fi

          touch "$state/vulns-found"
          webhook="$(cat ${config.sops.secrets."discord/ein-webhook".path})"
          payload_json="$(${pkgs.jq}/bin/jq -n \
            --arg t "**Vulnix System Scan**" \
            --arg c "$total CVEs across $nd derivation(s)" \
            --arg e "🔴 $crit | 🟠 $high | 🟡 $med | 🟢 $low | ⚪ $unk" \
            '{content: ($t + "\n" + $c + "\n" + $e)}')"
          ${pkgs.curl}/bin/curl -fsS -m 15 \
            -F "payload_json=$payload_json" \
            -F "file=@$report_txt;filename=vulnix-report.txt" \
            "$webhook" > /dev/null 2>&1 || true
          exit 1
        '';
      };
    };

    systemd.timers.vulnix-scan = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "Mon *-*-* 15:00:00";
        Persistent = true;
        Unit = "vulnix-scan.service";
      };
    };
  };
}
