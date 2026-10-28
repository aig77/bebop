_: {
  flake.modules.nixos.grafana-dashboards-unbound = {config, ...}: {
    observability.grafanaDashboards."unbound.json" = {
      url = "https://grafana.com/api/dashboards/11705/revisions/1/download";
      sha256 = "sha256-Thje1QgDEb+Qyj3FlwG6syIl/86vs6L7qX53NkctsZk=";
    };
  };
}
