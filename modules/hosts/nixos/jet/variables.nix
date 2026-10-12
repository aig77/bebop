_: {
  configurations.nixos.jet.role = "server";
  configurations.nixos.jet.module = {config, ...}: {
    var = {
      username = "arturo";
      hostname = "jet";
      shell = "zsh";
      observability = {
        # Remote metrics targets, scraped over the tailnet. This host's own
        # node exporter is scraped on loopback and is not listed here.
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
      services.blocky = {
        host = "ed";
        port = 53;
        monitor = {
          enable = true;
          interval = "1m";
          dns = {
            queryName = "example.com";
          };
        };
      };
    };
  };
}
