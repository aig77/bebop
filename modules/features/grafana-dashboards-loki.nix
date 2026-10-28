_: {
  flake.modules.nixos.grafana-dashboards-loki = {
    observability.grafanaDashboards."loki.json" = {
      url = "https://grafana.com/api/dashboards/13639/revisions/2/download";
      sha256 = "sha256-2dRUkooIA1E0Qshg58N+9duIW25iRruu1oW8ckBUNIA=";
    };
  };
}
