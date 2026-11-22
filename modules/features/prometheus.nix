{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  fleet.services.prometheus = {
    module = config.flake.modules.nixos.prometheus;
    category = "Observability";
    monitor = {
      enable = true;
      http = {
        path = "/-/healthy";
      };
    };
  };

  flake.modules.nixos.prometheus = {
    config,
    lib,
    ...
  }: let
    # Every target carries its own port from the owner's fleet table. The
    # stack itself is covered by the loopback target below.
    mkTarget = t: "${config.net.addrOf t.host}:${toString t.port}";
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
    # exporter too.
    imports = with nixos; [node-exporter];

    services.prometheus = {
      enable = true;
      # Loopback only: tailscale-http binds this same port on the tailnet IP.
      listenAddress = "127.0.0.1";
      port = config.ports.prometheus;
      retentionTime = "7d";
      scrapeConfigs =
        [
          {
            job_name = "prometheus";
            static_configs = [{targets = ["127.0.0.1:${toString config.ports.prometheus}"];}];
          }
          {
            job_name = "node";
            static_configs = [{targets = ["${config.var.hostname}:${toString config.ports.nodeExporter}"] ++ nodeTargets;}];
          }
        ]
        ++ extraJobs;
    };
  };
}
