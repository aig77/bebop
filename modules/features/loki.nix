_: {
  flake.modules.nixos.loki = {config, ...}: {
    var.services.loki = {
      subdomain = "logs";
      port = config.ports.loki;
      public = false;
      auth = false;
      backup.paths = ["/var/lib/loki"];
      monitor = {
        enable = true;
        type = "http";
        path = "/ready";
      };
    };

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_address = "0.0.0.0";
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

    networking.firewall.allowedTCPPorts = [config.ports.loki];
  };

  flake.modules.nixos.alloy = {
    config,
    pkgs,
    ...
  }: let
    pushTarget =
      if config.var.hostname == "jet"
      then "127.0.0.1"
      else config.var.network.hosts.jet;
  in {
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
            url = "http://${pushTarget}:${toString config.ports.loki}/loki/api/v1/push"
          }
        }
      '';
    };

    systemd.services.alloy.after = ["network-online.target"];
    systemd.services.alloy.wants = ["network-online.target"];
  };
}
