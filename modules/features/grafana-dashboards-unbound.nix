_: {
  flake.modules.nixos.grafana-dashboards-unbound = {
    observability.grafanaDashboards."unbound.json" = {
      url = "https://grafana.com/api/dashboards/21006/revisions/4/download";
      sha256 = "sha256-Z+y+8MCIpjgPW12Q2jcbNhaL/WA00SL2uPT/7KKsOVw=";
    };
  };
}
