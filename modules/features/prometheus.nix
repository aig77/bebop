{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.prometheus = {
    config,
    lib,
    ...
  }: let
    nodeExporterPort = config.ports.prometheus.nodeExporter;
    # Every remote target is scraped on the tailnet; the stack itself is
    # covered by the loopback target. job "node" uses the exporter's standard
    # port unless the target overrides it.
    mkTarget = t: "${config.net.addrOf t.host}:${toString (
      if t.port != null
      then t.port
      else nodeExporterPort
    )}";
    targetsByJob = lib.groupBy (t: t.job) config.observability.scrapeTargets;
    nodeTargets = map mkTarget (targetsByJob.node or []);
    extraJobs =
      lib.mapAttrsToList (job: targets: {
        job_name = job;
        static_configs = [{targets = map mkTarget targets;}];
      })
      (lib.removeAttrs targetsByJob ["node"]);
  in {
    # The stack host scrapes its own metrics, so it runs the agent's node
    # exporter too. The exporter definition lives in prometheus-client.
    imports = [nixos.prometheus-client];

    serviceRegistry.prometheus = {
      port = config.ports.prometheus.server;
      monitor = {
        enable = true;
        http = {
          path = "/-/healthy";
        };
      };
    };

    services.prometheus = {
      enable = true;
      # Loopback only: tailscale-http binds this same port on the tailnet IP.
      listenAddress = "127.0.0.1";
      port = config.ports.prometheus.server;
      retentionTime = "7d";
      scrapeConfigs =
        [
          {
            job_name = "prometheus";
            static_configs = [{targets = ["127.0.0.1:${toString config.ports.prometheus.server}"];}];
          }
          {
            job_name = "node";
            static_configs = [{targets = ["${config.var.hostname}:${toString nodeExporterPort}"] ++ nodeTargets;}];
          }
        ]
        ++ extraJobs;
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
