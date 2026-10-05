_: {
  flake.modules.nixos = {
    invidious = {
      config,
      pkgs,
      ...
    }: {
      var.services.invidious = {
        port = config.ports.invidious;
        expose = {
          subdomain = "invidious";
          basicAuth = true;
        };
        backup = {
          paths = ["/var/lib/backups/invidious.sql"];
          prepareCommand = ''
            mkdir -p /var/lib/backups
            ${pkgs.util-linux}/bin/runuser -u postgres -- ${pkgs.postgresql}/bin/pg_dump invidious > /var/lib/backups/invidious.sql
          '';
        };
      };

      sops = {
        secrets = {
          "invidious/companion-key" = {};
          "cloudflare/service-domain" = {};
        };

        templates = {
          "invidious-companion-settings.json" = {
            mode = "0444";
            content = ''
              {"invidious_companion":[{"private_url":"http://127.0.0.1:${toString config.ports.invidiousCompanion}/companion"}],"invidious_companion_key":"${config.sops.placeholder."invidious/companion-key"}","https_only":true,"domain":"invidious.${config.sops.placeholder."cloudflare/service-domain"}"}
            '';
          };

          "invidious-companion.env" = {
            mode = "0444";
            content = ''
              SERVER_SECRET_KEY=${config.sops.placeholder."invidious/companion-key"}
              PORT=${toString config.ports.invidiousCompanion}
            '';
          };
        };
      };

      # TODO: declare OCI container setup for invidious

      systemd.services = {
        # TODO: pull latest container
        invidious-update = {};

        # TODO: monitor invidious down and pull latest after extended downtime
        invidious-monitor = {};
      };

      # TODO: verify this is correct with new version
      timers.invidious-monitor = {
        description = "Invidious health check every 5 minutes";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
        };
      };
    };

    invidious-status = {
      config,
      pkgs,
      ...
    }: {
      assertions = [
        {
          assertion = config.var.services ? invidious;
          message = "invidious-status requires invidious to be enabled";
        }
      ];

      var.services.invidious-status = {
        port = config.ports.invidiousStatus;
        expose = {subdomain = "invidious-status";};
      };

      sops = {
        secrets."cloudflare/service-domain" = {};

        templates."gatus-invidious.yaml" = {
          mode = "0444";
          content = ''
            web:
              port: ${toString config.ports.invidiousStatus}
            storage:
              type: sqlite
              path: /var/lib/gatus-invidious/data.db
            ui:
              title: Invidious Health Dashboard
              header: invidious.${config.sops.placeholder."cloudflare/service-domain"}
              dashboard-heading: Invidious Status
              dashboard-subheading: Is my Invidious instance up?
              logo: https://invidious.io/invidious-colored-vector.svg
              link: https://invidious.${config.sops.placeholder."cloudflare/service-domain"}
              buttons:
                - name: Open Invidious
                  link: https://invidious.${config.sops.placeholder."cloudflare/service-domain"}
              custom-css: |
                #global {
                  background-color: #121212;
                  color: #efefef;
                }
                #global .dashboard-container {
                  background-color: #121212;
                }
                #global .endpoint, #global .endpoint-group {
                  background-color: #1e1e2e;
                  border: 1px solid #2a2a2a;
                }
                #global .endpoint-header, #global .endpoint-group-header {
                  background-color: #181825;
                  color: #cdd6f4;
                }
                #global .endpoint-content, #global .endpoint-group-content {
                  background-color: #1e1e2e;
                  color: #cdd6f4;
                }
                #global a { color: #f14336; }
                #global a:hover { color: #ff6659; }
            endpoints:
              - name: Invidious
                url: http://localhost:${toString config.ports.invidious}/api/v1/stats
                interval: 5m
                conditions:
                  - "[STATUS] == 200"
              - name: YouTube API
                url: http://localhost:${toString config.ports.invidious}/api/v1/trending
                interval: 15m
                conditions:
                  - "[STATUS] == 200"
                  - "[BODY] != []"
          '';
        };
      };

      systemd.services.gatus-invidious = {
        description = "Invidious public status page";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          ExecStart = "${pkgs.gatus}/bin/gatus";
          Environment = "GATUS_CONFIG_PATH=${config.sops.templates."gatus-invidious.yaml".path}";
          StateDirectory = "gatus-invidious";
          DynamicUser = true;
          Restart = "on-failure";
        };
      };
    };
  };
}
