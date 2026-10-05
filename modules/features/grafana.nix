_: {
  flake.modules.nixos.grafana = {
    config,
    pkgs,
    ...
  }: {
    var.services.grafana = {
      port = config.ports.grafana;
      backup.paths = ["/var/lib/grafana"];
      monitor = {
        enable = true;
        type = "http";
        path = "/api/health";
      };
      homepage = {
        enable = true;
        icon = "si:grafana";
      };
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = config.ports.grafana;
        };
        # NixOS 26.05 removed the default secret_key. Since auth is disabled and
        # there are no encrypted secrets in the DB, the old default is safe to hardcode.
        security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
        "auth.anonymous" = {
          enabled = true;
          org_role = "Admin";
        };
        panels.disable_sanitize_html = true;
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString config.ports.prometheus.server}";
            isDefault = true;
          }
        ];
        dashboards.settings.providers = [
          {
            name = "default";
            options.path = "/etc/grafana-dashboards";
          }
        ];
      };
    };

    environment.etc = {
      "grafana-dashboards/node-exporter.json".source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
        sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
      };
      "grafana-dashboards/blocky.json".source = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/13768/revisions/latest/download";
        sha256 = "sha256-gwPOcnVC7BXTlhOCRvENAXZfGdQGVCPEUrLCl4ASkVE=";
      };
    };
  };
}
