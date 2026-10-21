_: {
  configurations.nixos.jet.module = {config, ...}: {
    ports = {
      glance = 3000;
      n8n = 3020;
      grafana = 3030;
      gatus = 3040;
      prometheus = config.mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      dailyStoic = 3060;
      vaultwarden = 3070;
      actualBudget = 3080;
      subtrakr = 3090;
      # blockyHttp + nodeExporter are scraped from ed over the tailnet; same
      # numbers ed binds (modules/hosts/nixos/ed/ports.nix).
      blockyHttp = 4000;
      open-webui = 4010;
      searx = 4020;
      forgejo = 4030;
      dbgate = 4040;
      loki = 3160;
      sure = config.mkPortGroup {
        base = 4050;
        names = ["webUI" "redis"];
      };
      postgres = config.mkPortGroup {
        base = 5432; # default
        names = ["server" "exporter"];
      };
    };

    # Remote metrics targets, scraped over the tailnet. This host's own
    # node exporter is scraped on loopback and is not listed here.
    observability = {
      scrapeTargets = [
        {
          job = "node";
          host = "ed";
        }
        {
          job = "blocky";
          host = "ed";
          port = config.ports.blockyHttp;
        }
      ];
    };

    # Remote DNS service on ed; gatus probes it with a real DNS query.
    serviceRegistry.blocky = {
      host = "ed";
      port = 53;
      category = "Infrastructure";
      monitor = {
        enable = true;
        interval = "1m";
        dns = {
          queryName = "example.com";
        };
      };
    };
  };
}
