_: {
  flake.modules.nixos.grafana-dashboards-node-exporter = {
    observability.grafanaDashboards."node-exporter.json" = {
      url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
      sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
    };
  };
}
