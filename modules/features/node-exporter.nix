_: {
  flake.modules.nixos.node-exporter = {config, ...}: {
    services.prometheus.exporters.node = {
      enable = true;
      port = config.ports.prometheus.nodeExporter;
    };

    observability.grafanaDashboards."node-exporter.json" = {
      url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
      sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
    };
  };
}
