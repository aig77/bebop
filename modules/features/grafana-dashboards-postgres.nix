_: {
  flake.modules.nixos.grafana-dashboards-postgres = {
    observability.grafanaDashboards."postgres.json" = {
      url = "https://grafana.com/api/dashboards/9628/revisions/8/download";
      sha256 = "sha256-UhusNAZbyt7fJV/DhFUK4FKOmnTpG0R15YO2r+nDnMc=";
    };
  };
}
