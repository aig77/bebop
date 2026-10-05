_: {
  flake.modules.nixos.prometheus = {config, ...}: let
    edIp = config.var.network.addrOf "ed";
  in {
    var.services.prometheus = {
      port = config.ports.prometheus.server;
    };

    services.prometheus = {
      enable = true;
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

  flake.modules.nixos.prometheus-client = {config, ...}: {
    services.prometheus.exporters.node = {
      enable = true;
      port = config.ports.prometheus.nodeExporter;
    };
    networking.firewall.allowedTCPPorts = [config.ports.prometheus.nodeExporter];
  };
}
