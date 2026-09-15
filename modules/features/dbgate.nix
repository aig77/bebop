_: {
  flake.modules.nixos.dbgate = {
    config,
    lib,
    ...
  }: let
    image = "docker.io/dbgate/dbgate:latest";
  in {
    # Expose postgres to the podman default bridge so containerized workloads
    # (dbgate, future pg-backed containers) can reach the host instance over TCP.
    #
    # Podman 5 defaults: bridge interface podman0, subnet 10.88.0.0/16, gateway
    # 10.88.0.1. If the default network ever changes, update this whole module.
    #
    # Postgres binds 0.0.0.0 instead of "localhost,10.88.0.1" because podman0 is
    # created lazily at container start, after postgres boots; binding a
    # not-yet-existing address would crash postgres. Safety still comes from:
    #   - pg_hba: only loopback (md5) and whatever line consumers add for
    #     10.88.0.0/16 may connect over TCP (each consumer scopes its own role)
    #   - the NixOS firewall: 5432 open on podman0 only, nothing on LAN/tailnet
    services.postgresql.settings.listen_addresses = lib.mkForce "0.0.0.0";
    networking.firewall.interfaces.podman0.allowedTCPPorts = [5432];

    var.services.dbgate = {
      subdomain = "dbgate";
      port = config.ports.dbgate;
      public = false;
      auth = false;
      backup.paths = ["/var/lib/dbgate"];
      monitor = {
        enable = true;
        type = "tcp";
        interval = "1m";
      };
      homepage = {
        enable = true;
        title = "DbGate";
        icon = "mdi:database";
      };
    };

    # Trust auth from the podman bridge for the dbgate role only. No resource names
    # hardcoded: dbgate connects to any database on the instance.
    services.postgresql.authentication = lib.mkAfter ''
      host all dbgate 10.88.0.0/16 trust
    '';

    # Connections are created in the DbGate UI and persisted in /root/.dbgate;
    # no CONNECTIONS env vars, so add/edit stays available and survives restic restores.
    systemd.tmpfiles.rules = ["d /var/lib/dbgate 0755 root root -"];

    virtualisation = {
      podman.enable = true;
      oci-containers.containers.dbgate = {
        inherit image;
        ports = ["127.0.0.1:${toString config.ports.dbgate}:3000"];
        volumes = [
          "/var/lib:/data"
          "/var/lib/dbgate:/root/.dbgate"
        ];
      };
    };

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
  };
}
