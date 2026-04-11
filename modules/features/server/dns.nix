_: {
  flake.modules.nixos.server = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets = {
      grafana-admin-password = {
        owner = "grafana";
        group = "grafana";
      };
      grafana-secret-key = {
        owner = "grafana";
        group = "grafana";
      };
    };

    services = {
      blocky = {
        enable = true;
        settings = {
          ports = {
            dns = 53;
            http = 4000;
          };

          upstreams.groups.default = [
            "https://one.one.one.one/dns-query"
          ];

          bootstrapDns = {
            upstream = "https://one.one.one.one/dns-query";
            ips = ["1.1.1.1" "1.0.0.1"];
          };

          blocking = {
            denylists = {
              ads = ["https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"];
            };
            clientGroupsBlock = {
              default = ["ads"];
            };
          };

          prometheus = {
            enable = true;
            path = "/metrics";
          };
        };
      };

      unbound = {
        enable = true;
        settings.server = {
          port = 5335;
          interface = "127.0.0.1";
          access-control = [
            "127.0.0.1 allow"
            "::1 allow"
          ];
          do-ip4 = true;
          do-ip6 = true;
          prefer-ip6 = false;
          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          edns-buffer-size = 1232;
          prefetch = true;
          prefetch-key = true;
        };
        settings.remote-control.control-enable = false;
      };

      prometheus = {
        enable = true;
        port = 9090;
        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [{targets = ["127.0.0.1:9090"];}];
          }
          {
            job_name = "node";
            static_configs = [{targets = ["127.0.0.1:9100"];}];
          }
          {
            job_name = "blocky";
            static_configs = [{targets = ["127.0.0.1:4000"];}];
          }
        ];
        exporters.node = {
          enable = true;
          port = 9100;
        };
        retentionTime = "7d";
      };

      grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
          };
          security = {
            admin_password_path = "${config.sops.secrets.grafana-admin-password.path}";
            secret_key = "$__file{${config.sops.secrets.grafana-secret-key.path}}";
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:9090";
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
    };

    environment.etc."grafana-dashboards/node-exporter.json".source = pkgs.fetchurl {
      url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
      sha256 = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        53
        3000
        9090
      ];
      allowedUDPPorts = [
        53
      ];
    };
  };
}
