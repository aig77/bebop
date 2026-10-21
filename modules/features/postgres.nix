_: {
  flake.modules.nixos.postgres = {
    config,
    pkgs,
    lib,
    ...
  }: {
    serviceRegistry.postgres = {
      port = config.ports.postgres.server;
      category = "Infrastructure";
      # A database is not an HTTP service: tailscale-http would wrap the PG
      # wire protocol in an HTTPS proxy. Monitor it, do not route it.
      serve = false;
      monitor = {
        enable = true;
        tcp = {};
      };
    };

    services = {
      postgresql = {
        enable = lib.mkForce true;
        package = pkgs.postgresql_16;
        port = config.ports.postgres.server;
        settings.listen_addresses = lib.mkForce "*";
      };

      # Scraped on loopback, like the stack host's own node exporter. The
      # exporter runs as the postgres OS user and reaches the database through
      # the unix socket, so peer auth covers it and no password is stored.
      prometheus.exporters.postgres = lib.mkIf config.services.postgresql.enable {
        enable = true;
        runAsLocalSuperUser = true;
        listenAddress = "127.0.0.1";
        port = config.ports.postgres.exporter;
      };

      prometheus.scrapeConfigs = lib.mkIf (config.services.postgresql.enable && config.services.prometheus.enable) [
        {
          job_name = "postgres";
          static_configs = [{targets = ["127.0.0.1:${toString config.ports.postgres.exporter}"];}];
        }
      ];
    };

    # Allow containers to connect over the podman bridge
    networking.firewall.interfaces.podman0.allowedTCPPorts = [config.ports.postgres.server];
  };
}
