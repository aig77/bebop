_: {
  flake.modules.nixos.adguard = {
    config,
    lib,
    ...
  }: {
    services.adguardhome = {
      enable = true;
      # Web UI/API on all interfaces. The LAN port is firewalled, so only the
      # tailnet reaches it (same exposure blocky's API had).
      host = "0.0.0.0";
      port = config.ports.dns.http;
      # Seed the config from Nix, but keep the web UI authoritative afterwards
      # so settings can still be changed from the dashboard.
      mutableSettings = true;
      settings = {
        # No web credentials: the UI/API is tailnet-only. Add a users entry
        # (a bcrypt hash) to require login.
        users = [];
        dns = {
          bind_hosts = ["0.0.0.0"];
          port = 53;
          # unbound does local recursion + DNSSEC; cloudflare is the failover.
          upstream_dns = ["127.0.0.1:${toString config.ports.dns.unbound}"];
          fallback_dns = ["https://one.one.one.one/dns-query"];
          bootstrap_dns = ["1.1.1.1:53"];
          # Not internet-facing, so no query-rate limiting.
          ratelimit = 0;
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
        };
        filters = [
          {
            enabled = true;
            id = 1;
            name = "HaGeZi - Multi PRO";
            url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
          }
          {
            enabled = true;
            id = 2;
            name = "HaGeZi - TIF (medium)";
            url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.medium.txt";
          }
        ];
        querylog.enabled = true;
        # /control/stats (read by glance's DNS widget) needs statistics on.
        statistics.enabled = true;
      };
    };

    networking.firewall = {
      enable = true;
      # 53 stays open for LAN DNS clients. The web UI/API is read over the
      # tailnet, so its port stays off the LAN.
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    systemd.services.adguardhome = lib.mkIf config.services.unbound.enable {
      after = ["unbound.service"];
      wants = ["unbound.service"];
    };
  };
}
