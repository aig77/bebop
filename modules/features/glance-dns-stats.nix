_: {
  # A blocky DNS dashboard for glance. Glance's native `dns-stats` widget only
  # speaks adguard / pihole / technitium, so this renders blocky's own
  # `GET /api/stats` JSON (blocky >= 0.32, enabled in features/dns.nix) through
  # a `custom-api` widget, mimicking the native widget's look.
  #
  # Runs on the glance host (jet) and reads the remote blocky on ed over the
  # tailnet. Guarded on a registered `blocky` service so it disappears if DNS
  # ever moves.
  flake.modules.nixos.glance-dns-stats = {
    config,
    lib,
    ...
  }: {
    glance.extraWidgets.dns = lib.mkIf (config.serviceRegistry ? blocky) [
      {
        type = "custom-api";
        title = "DNS";
        cache = "1m";
        url = "http://${config.net.addrOf "ed"}:${toString config.ports.blockyHttp}/api/stats";
        title-url = "https://${config.var.hostname}.\${TAILNET}:${toString config.ports.gatus}";
        template = ''
          <style>
            .blk-dns .blk-totals { display: flex; justify-content: space-between; text-align: center; }
            .blk-dns .blk-graph { display: flex; align-items: flex-end; gap: 2px; height: 64px; margin-top: 1rem; }
            .blk-dns .blk-col { flex: 1 1 0; display: flex; align-items: flex-end; min-width: 0; }
            .blk-dns .blk-bar {
              width: 100%;
              height: calc((var(--bar-height, 0) / 100) * 64px);
              min-height: 3px;
              display: flex;
              flex-direction: column;
              justify-content: flex-end;
              overflow: hidden;
              background: var(--color-vertical-progress-value);
              border: 1px solid var(--color-progress-border);
              border-radius: 3px 3px 0 0;
            }
            .blk-dns .blk-blocked { width: 100%; height: calc(var(--bar-blocked, 0) * 1%); background: var(--color-negative); }
            .blk-dns .blk-domains { margin-top: 1rem; }
          </style>

          {{ $s := .JSON }}
          {{ $queries := $s.Int "summary.queries" }}
          {{ $blocked := $s.Int "summary.blocked" }}
          {{ $latency := $s.Int "summary.avgResponseMs" }}
          {{ $blockedPct := 0.0 }}
          {{ if gt $queries 0 }}{{ $blockedPct = div (mul (toFloat $blocked) 100.0) (toFloat $queries) }}{{ end }}

          <div class="blk-dns">
            <div class="blk-totals">
              <div>
                <div class="color-highlight size-h3">{{ $queries | formatNumber }}</div>
                <div class="size-h6">QUERIES</div>
              </div>
              <div>
                <div class="color-highlight size-h3">{{ printf "%.1f" $blockedPct }}%</div>
                <div class="size-h6">BLOCKED</div>
              </div>
              <div>
                <div class="color-highlight size-h3">{{ $latency }}ms</div>
                <div class="size-h6">LATENCY</div>
              </div>
            </div>

            {{ $hours := $s.Array "perHour" }}
            {{ if $hours }}
              {{ $max := 1 }}
              {{ range $hours }}{{ $q := .Int "queries" }}{{ if gt $q $max }}{{ $max = $q }}{{ end }}{{ end }}
              <div class="blk-graph">
                {{ range $hours }}
                  {{ $q := .Int "queries" }}
                  {{ $b := .Int "blocked" }}
                  {{ $hp := 0.0 }}
                  {{ if gt $q 0 }}{{ $hp = div (mul (toFloat $q) 100.0) (toFloat $max) }}{{ end }}
                  {{ $bp := 0.0 }}
                  {{ if gt $q 0 }}{{ $bp = div (mul (toFloat $b) 100.0) (toFloat $q) }}{{ end }}
                  <div class="blk-col">
                    <div class="blk-bar" style="--bar-height: {{ printf "%.1f" $hp }}">
                      {{ if gt $b 0 }}<div class="blk-blocked" style="--bar-blocked: {{ printf "%.1f" $bp }}"></div>{{ end }}
                    </div>
                  </div>
                {{ end }}
              </div>
            {{ end }}

            {{ $domains := $s.Array "topBlockedDomains" }}
            {{ if $domains }}
              <ul class="list list-gap-4 list-with-transition size-h5 blk-domains">
                {{ range $domains }}
                  {{ $c := .Int "count" }}
                  {{ $pct := 0.0 }}
                  {{ if gt $blocked 0 }}{{ $pct = div (mul (toFloat $c) 100.0) (toFloat $blocked) }}{{ end }}
                  <li class="flex justify-between gap-10">
                    <div class="text-truncate rtl">{{ .String "name" }}</div>
                    <div class="text-right" style="width: 4rem;"><span class="color-highlight">{{ printf "%.1f" $pct }}</span>%</div>
                  </li>
                {{ end }}
              </ul>
            {{ end }}
          </div>
        '';
      }
    ];
  };
}
