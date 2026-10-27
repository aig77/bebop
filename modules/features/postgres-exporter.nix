_: {
  flake.modules.nixos.postgres-exporter = {config, lib, ...}: {
    services.prometheus.exporters.postgres = lib.mkIf config.services.postgresql.enable {
      enable = true;
      runAsLocalSuperUser = true;
      listenAddress = "127.0.0.1";
      port = config.ports.postgres.exporter;
    };

    services.prometheus.scrapeConfigs = lib.mkIf (config.services.postgresql.enable && config.services.prometheus.enable) [
      {
        job_name = "postgres";
        static_configs = [{targets = ["127.0.0.1:${toString config.ports.postgres.exporter}"];}];
      }
    ];
  };
}
