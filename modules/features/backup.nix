_: {
  flake.modules.nixos.backup = {
    config,
    lib,
    pkgs,
    ...
  }: let
    backupServices = lib.filterAttrs (_: s: s.backup != null && s.host == config.var.hostname) config.var.services;

    # Postgres dump name defaults to the service key.
    dbName = name: s:
      if s.backup.database.name != null
      then s.backup.database.name
      else name;

    dbPrepare = name: s:
      if s.backup.database == null
      then ""
      else if s.backup.database.type == "postgres"
      then ''
        mkdir -p /var/lib/backups/${name}
        ${pkgs.util-linux}/bin/runuser -u postgres -- ${pkgs.postgresql}/bin/pg_dump ${dbName name s} > /var/lib/backups/${name}/dump.sql
      ''
      else ''
        mkdir -p /var/lib/backups/${name}
        ${pkgs.sqlite}/bin/sqlite3 ${s.backup.database.path} ".backup '/var/lib/backups/${name}/${baseNameOf s.backup.database.path}'"
      '';

    dbPaths = name: s:
      if s.backup.database == null
      then []
      else ["/var/lib/backups/${name}"];

    allPaths = lib.concatMap (name: backupServices.${name}.backup.paths ++ dbPaths name backupServices.${name}) (lib.attrNames backupServices);

    prepareCommands = lib.concatStringsSep "\n" (
      lib.filter (s: s != "") (lib.mapAttrsToList dbPrepare backupServices)
    );
  in {
    assertions =
      lib.mapAttrsToList (name: s: {
        assertion = s.backup.database == null || s.backup.database.type != "sqlite" || s.backup.database.path != null;
        message = "var.services.${name}: backup.database.type = sqlite requires backup.database.path";
      })
      backupServices;

    sops = {
      secrets = {
        "restic/password" = {};
        "restic/r2-repository" = {};
        "restic/r2-access-key" = {};
        "restic/r2-secret-key" = {};
      };

      templates."restic.env" = {
        mode = "0400";
        content = ''
          RESTIC_REPOSITORY=${config.sops.placeholder."restic/r2-repository"}
          AWS_ACCESS_KEY_ID=${config.sops.placeholder."restic/r2-access-key"}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."restic/r2-secret-key"}
        '';
      };
    };

    services.restic.backups.${config.var.hostname} = {
      passwordFile = config.sops.secrets."restic/password".path;
      environmentFile = config.sops.templates."restic.env".path;
      paths = allPaths;
      backupPrepareCommand = lib.optionalString (prepareCommands != "") prepareCommands;
      backupCleanupCommand = "rm -rf /var/lib/backups";
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 3"];
      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
      initialize = true;
    };
  };
}
