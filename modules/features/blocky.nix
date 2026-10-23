_: {
  flake.modules.nixos.blocky = {
    config,
    pkgs,
    ...
  }: {
    services = {
      blocky = {
        enable = true;
        # The /api/stats endpoint that feeds glance's DNS widget landed in
        # blocky 0.32; stable ships 0.29, so pull the one package from unstable.
        package = pkgs.unstable.blocky;
        settings = {
          ports = {
            dns = 53;
            http = config.ports.dnsHttp;
          };

          # In-memory 24h stats, served as JSON at /api/stats (off by default).
          statistics.enable = true;

          upstreams = {
            strategy = "strict";
            groups.default = [
              "tcp+udp:127.0.0.1:${toString config.ports.unbound}" # unbound: local recursion + DNSSEC
              "https://one.one.one.one/dns-query" # cloudflare: strict-order failover
            ];
          };

          bootstrapDns = {
            upstream = "https://one.one.one.one/dns-query";
            ips = ["1.1.1.1" "1.0.0.1"];
          };

          blocking = {
            denylists = {
              ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
            };
            clientGroupsBlock = {
              default = ["ads"];
            };
          };

          prometheus = {
            enable = true;
            path = "/metrics";
          };
        };
      };
    };

    networking.firewall = {
      enable = true;
      # 53 stays open for LAN DNS clients. Blocky's metrics and stats API
      # (dnsHttp) are read over the tailnet, so they stay off the LAN.
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    systemd.services.blocky = {
      after = ["unbound.service"];
      wants = ["unbound.service"];
    };
  };
}
