_: {
  flake.modules.nixos.prometheus = {config, ...}: let
    edIp = config.var.network.addrOf "ed";
  in {
    var.services.prometheus = {
      port = config.ports.prometheus.server;
    };

    services.prometheus = {
      enable = true;
      # Loopback only: tailscale-http binds this same port on the tailnet IP.
      listenAddress = "127.0.0.1";
      port = config.ports.prometheus.server;
      retentionTime = "7d";
      exporters.node = {
        enable = true;
        port = config.ports.prometheus.nodeExporter;
      };
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [{targets = ["127.0.0.1:${toString config.ports.prometheus.server}"];}];
        }
        {
          job_name = "node";
          static_configs = [
            {targets = ["127.0.0.1:${toString config.ports.prometheus.nodeExporter}" "${edIp}:${toString config.ports.prometheus.nodeExporter}"];}
          ];
        }
        {
          job_name = "blocky";
          static_configs = [{targets = ["${edIp}:${toString config.ports.blockyHttp}"];}];
        }
      ];
    };
  };

  # Node exporter is scraped over the tailnet. tailscaled permits tailnet
  # traffic, so no firewall opening is needed - the port stays off the LAN.
  flake.modules.nixos.prometheus-client = {config, ...}: {
    services.prometheus.exporters.node = {
      enable = true;
      port = config.ports.prometheus.nodeExporter;
    };
  };
}
