_: {
  flake.modules.nixos.dbgate = {
    config,
    lib,
    ...
  }: {
    serviceRegistry.dbgate = {
      port = config.ports.dbgate;
      category = "Development";
      backup.paths = ["/var/lib/dbgate"];
      monitor = {
        enable = true;
        interval = "1m";
        tcp = {};
      };
      homepage = {
        enable = true;
        title = "DbGate";
        icon = "di:dbgate";
      };
    };

    # Allow dbgate TCP access from podman bridge (10.88.0.0/16)
    services.postgresql.authentication = lib.mkAfter ''
      host all dbgate 10.88.0.0/16 trust
    '';

    # Connections are created in the DbGate UI and persisted in /root/.dbgate;
    # no CONNECTIONS env vars, so add/edit stays available and survives restic restores.
    systemd.tmpfiles.rules = ["d /var/lib/dbgate 0755 root root -"];

    # DbGate postgres role: broad read/write via postgres's own pg_read_all_data /
    # pg_write_all_data roles, so no per-service grants are hardcoded here.
    systemd.services.dbgate-postgres-role = {
      description = "Create dbgate postgres role for DbGate";
      after = ["postgresql.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "postgres";
        Group = "postgres";
      };
      script = ''
        ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 <<'SQL'
        DO $$
        BEGIN
          IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dbgate') THEN
            CREATE ROLE dbgate LOGIN;
          END IF;
        END
        $$;
        GRANT pg_read_all_data TO dbgate;
        GRANT pg_write_all_data TO dbgate;
        SQL
      '';
    };

    virtualisation = {
      podman.enable = true;
      oci-containers.containers.dbgate = {
        image = "docker.io/dbgate/dbgate:latest";
        ports = ["127.0.0.1:${toString config.ports.dbgate}:3000"];
        volumes = [
          "/var/lib:/data"
          "/var/lib/dbgate:/root/.dbgate"
        ];
      };
    };
  };
}
