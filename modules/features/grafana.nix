_: {
  flake.modules.nixos.grafana = {
    config,
    pkgs,
    lib,
    ...
  }: {
    serviceRegistry.grafana = {
      port = config.ports.grafana;
      category = "Observability";
      backup.paths = ["/var/lib/grafana"];
      monitor = {
        enable = true;
        http = {
          path = "/api/health";
        };
      };
      homepage = {
        enable = true;
        icon = "di:grafana";
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
          {
            name = "Loki";
            type = "loki";
            uid = "loki";
            url = "http://${config.net.addrOf config.observability.lokiHost}:${toString config.ports.loki}";
            access = "proxy";
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

    environment.etc =
      lib.mapAttrs'
      (filename: dash: let
        finalName =
          if dash.name != null
          then dash.name
          else filename;
      in
        lib.nameValuePair "grafana-dashboards/${finalName}" {
          source = pkgs.fetchurl {
            inherit (dash) url sha256;
          };
        })
      config.observability.grafanaDashboards;
  };
}
