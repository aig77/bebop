_: {
  flake.modules.nixos.unbound-exporter = {
    config,
    pkgs,
    ...
  }: let
    port = config.ports.dns.unboundExporter;
  in {
    systemd.services.prometheus-unbound-exporter = {
      description = "Prometheus exporter for Unbound (letsencrypt)";
      wantedBy = ["multi-user.target"];
      after = ["unbound.service"];
      requires = ["unbound.service"];

      serviceConfig = {
        DynamicUser = true;
        SupplementaryGroups = ["unbound"];
        Restart = "on-failure";
        ExecStart = ''
          ${pkgs.prometheus-unbound-exporter}/bin/unbound_exporter \
            -unbound.host unix:///run/unbound/unbound.ctl \
            -web.listen-address 127.0.0.1:${toString port}
        '';
      };
    };

    observability.grafanaDashboards."unbound.json" = {
      url = "https://grafana.com/api/dashboards/11705/revisions/1/download";
      sha256 = "sha256-Thje1QgDEb+Qyj3FlwG6syIl/86vs6L7qX53NkctsZk=";
    };
  };
}
