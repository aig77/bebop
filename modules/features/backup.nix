_: {
  flake.modules.nixos.backup = {
    config,
    lib,
    ...
  }: let
    backupServices = lib.filterAttrs (_: s: s.backup != null && s.host == config.var.hostname) config.var.services;
    allPaths = lib.concatMap (s: s.backup.paths) (lib.attrValues backupServices);
    prepareCommands = lib.concatStringsSep "\n" (
      lib.filter (s: s != "")
      (map (s: lib.optionalString (s.backup.prepareCommand != null) s.backup.prepareCommand)
        (lib.attrValues backupServices))
    );
  in {
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
