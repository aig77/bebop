_: {
  flake.modules.nixos.firefox-sync = {
    config,
    inputs,
    lib,
    pkgs,
    ...
  }: let
    syncHost = "${config.var.hostname}.${config.net.tailnet}";
    syncPort = config.ports.syncserver;
    # The stable module is MySQL-only. Pull the PostgreSQL-capable module and
    # package from unstable until they land in stable.
    syncPackage =
      inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.syncstorage-rs-pgsql;
  in {
    disabledModules = ["services/networking/firefox-syncserver.nix"];
    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/firefox-syncserver.nix"
    ];

    services.firefox-syncserver = {
      enable = true;
      package = syncPackage;

      database = {
        type = "postgresql";
        name = "firefox_syncserver";
        user = "firefox_syncserver";
        createLocally = false;
      };

      singleNode = {
        enable = true;
        hostname = syncHost;
        url = "https://${syncHost}:${toString syncPort}";
        enableTLS = false;
        enableNginx = false;
      };

      settings.port = syncPort;
      secrets = config.sops.templates."firefox-syncserver.env".path;
    };

    serviceRegistry.syncserver = {
      port = config.ports.syncserver;
      servePort = config.ports.syncserver;
      category = "Infrastructure";
      backup.database = {
        type = "postgres";
        name = "firefox_syncserver";
      };
      monitor = {
        enable = true;
        tcp = {};
      };
    };

    # The unstable syncserver module adds an option anchor that the stable
    # manual redirects file does not know; skip the redirects check.
    documentation.nixos.checkRedirects = false;

    # createLocally is off because jet already runs postgres, but the module
    # only creates the role and database when it owns the postgres service.
    services.postgresql = {
      ensureDatabases = lib.mkAfter ["firefox_syncserver"];
      ensureUsers = lib.mkAfter [
        {
          name = "firefox_syncserver";
          ensureDBOwnership = true;
        }
      ];
    };

    sops = {
      secrets."firefox-syncserver/master-secret" = {};

      templates."firefox-syncserver.env" = {
        mode = "0400";
        content = ''
          SYNC_MASTER_SECRET=${config.sops.placeholder."firefox-syncserver/master-secret"}
        '';
        restartUnits = ["firefox-syncserver.service"];
      };
    };

    assertions = [
      {
        assertion = config.services.postgresql.enable;
        message = "firefox-sync requires the postgres feature";
      }
    ];
  };
}
