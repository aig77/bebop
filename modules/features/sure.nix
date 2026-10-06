_: {
  flake.modules.nixos.sure = {
    config,
    lib,
    ...
  }: {
    var.services.sure = {
      port = config.ports.sure.webUI;
      monitor = {
        enable = true;
        type = "http";
        path = "/up";
        conditions = ["[STATUS] == 200"];
      };
      homepage = {
        enable = true;
        title = "Sure";
        icon = "di:sure";
      };
      backup = {
        paths = ["/var/lib/sure"];
        database = {
          type = "postgres";
          name = "sure_production";
        };
      };
    };

    sops = {
      secrets = {
        "sure/secret-key-base" = {};
        "sure/postgres-password" = {
          owner = "postgres";
        };
        "sure/redis-password" = {};
      };

      templates."sure.env" = {
        mode = "0400";
        content = ''
          SECRET_KEY_BASE=${config.sops.placeholder."sure/secret-key-base"}
          POSTGRES_PASSWORD=${config.sops.placeholder."sure/postgres-password"}
          POSTGRES_USER=sure_user
          POSTGRES_DB=sure_production
          DB_HOST=10.88.0.1
          DB_PORT=5432
          REDIS_URL=redis://:${config.sops.placeholder."sure/redis-password"}@10.88.0.1:${toString config.ports.sure.redis}/1
          SELF_HOSTED=true
          RAILS_ASSUME_SSL=true
          RAILS_FORCE_SSL=false
        '';
        restartUnits = ["podman-sure-web.service" "podman-sure-worker.service"];
      };
    };

    virtualisation = {
      podman.enable = true;
      oci-containers.containers = {
        sure-web = {
          image = "ghcr.io/we-promise/sure:stable";
          ports = ["127.0.0.1:${toString config.ports.sure.webUI}:3000"];
          volumes = ["/var/lib/sure/storage:/rails/storage"];
          environmentFiles = [config.sops.templates."sure.env".path];
        };
        sure-worker = {
          image = "ghcr.io/we-promise/sure:stable";
          cmd = ["bundle" "exec" "sidekiq"];
          volumes = ["/var/lib/sure/storage:/rails/storage"];
          environmentFiles = [config.sops.templates."sure.env".path];
        };
      };
    };

    services.postgresql = {
      enable = true;
      settings.listen_addresses = lib.mkForce "0.0.0.0";
      authentication = lib.mkAfter ''
        host all sure_user 10.88.0.0/16 scram-sha-256
      '';
    };

    services.redis.servers."sure" = {
      enable = true;
      port = config.ports.sure.redis;
      bind = "0.0.0.0";
      requirePassFile = config.sops.secrets."sure/redis-password".path;
      settings = {
        appendonly = "yes"; # sidekiq jobs survive restart
        maxmemory = "256mb";
        maxmemory-policy = "noeviction"; # never silently drop queued jobs
        protected-mode = "no"; # Redis refuses non-loopback clients and we're trying to use 0.0.0.0
      };
    };

    networking.firewall.interfaces.podman0.allowedTCPPorts = [5432 config.ports.sure.redis];

    systemd = {
      services = {
        sure-postgres = {
          description = "Create sure role and database on host postgres";
          after = ["postgresql.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "postgres";
            Group = "postgres";
          };
          script = ''
            PSQL=${config.services.postgresql.package}/bin/psql
            pw=$(cat ${config.sops.secrets."sure/postgres-password".path})
            $PSQL -v ON_ERROR_STOP=1 -v pw="$pw" <<'SQL'
            DO $$
            BEGIN
              IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'sure_user') THEN
                CREATE ROLE sure_user LOGIN;
              END IF;
            END
            $$;
            ALTER ROLE sure_user PASSWORD :'pw';
            SQL
            if ! $PSQL -tAc "SELECT 1 FROM pg_database WHERE datname = 'sure_production'" | grep -q 1; then
              ${config.services.postgresql.package}/bin/createdb -O sure_user sure_production
            fi
          '';
        };
        "podman-sure-web" = {
          after = ["sure-postgres.service"];
          requires = ["sure-postgres.service"];
        };
        "podman-sure-worker" = {
          after = ["sure-postgres.service"];
          requires = ["sure-postgres.service"];
        };
      };
      tmpfiles.rules = [
        "d /var/lib/sure 0755 root root -"
        "d /var/lib/sure/storage 0755 root root -"
      ];
    };
  };
}
