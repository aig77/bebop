_: {
  flake.modules.nixos.loki = {config, ...}: {
    serviceRegistry.loki = {
      port = config.ports.loki;
      category = "Observability";
      backup.paths = ["/var/lib/loki"];
      monitor = {
        enable = true;
        http = {
          path = "/ready";
        };
      };
    };

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          # Loopback only: tailscale-http binds this same port on the tailnet IP.
          http_listen_address = "127.0.0.1";
          http_listen_port = config.ports.loki;
        };
        common = {
          path_prefix = "/var/lib/loki";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
          replication_factor = 1;
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
        };
        schema_config.configs = [
          {
            from = "2022-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
        limits_config.retention_period = "720h";
        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "15m";
        };
      };
    };
  };

  flake.modules.nixos.alloy = {
    config,
    pkgs,
    ...
  }: let
    lokiHost = config.observability.lokiHost;
    # The stack host talks to Loki on loopback; agents reach it through
    # tailscale-http, which terminates TLS on the tailnet name.
    lokiUrl =
      if config.var.hostname == lokiHost
      then "http://127.0.0.1:${toString config.ports.loki}/loki/api/v1/push"
      else "https://${lokiHost}.${config.sops.placeholder."tailscale/tailnet"}:${toString config.ports.loki}/loki/api/v1/push";
  in {
    sops = {
      secrets."tailscale/tailnet" = {};
      templates."alloy.env" = {
        mode = "0400";
        content = "LOKI_URL=${lokiUrl}\n";
      };
    };

    services.alloy = {
      enable = true;
      configPath = pkgs.writeText "alloy.river" ''
        logging {
          level = "info"
        }

        loki.source.journal "journal" {
          labels = {
            job      = "journal",
            hostname = "${config.var.hostname}",
          }
          relabel_rules = loki.relabel.journal.rules
          forward_to = [loki.write.agent.receiver]
        }

        loki.relabel "journal" {
          forward_to = []

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
        }

        loki.write "agent" {
          endpoint {
            url = sys.env("LOKI_URL")
          }
        }
      '';
    };

    systemd.services.alloy = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig.EnvironmentFile = config.sops.templates."alloy.env".path;
    };
  };
}
