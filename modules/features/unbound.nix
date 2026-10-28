_: {
  flake.modules.nixos.unbound = {config, ...}: {
    services.unbound = {
      enable = true;
      localControlSocketPath = "/run/unbound/unbound.ctl";
      settings = {
        server = {
          port = config.ports.dns.unbound;
          interface = "127.0.0.1";
          extended-statistics = true;
          access-control = [
            "127.0.0.1 allow"
            "::1 allow"
          ];
          do-ip4 = true;
          do-ip6 = true;
          prefer-ip6 = false;
          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          edns-buffer-size = 1232;
          prefetch = true;
          prefetch-key = true;
        };
        forward-zone = [
          {
            name = "ts.net";
            forward-addr = ["100.100.100.100"];
          }
        ];
      };
    };
  };
}
