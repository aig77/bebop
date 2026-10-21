{lib, ...}: {
  flake.modules.nixos.base = {
    config,
    fleetHosts,
    ...
  }: {
    # TODO: consistent raw-file backups. Database dumps are
    # transactionally consistent (pg_dump, sqlite3 .backup), but paths
    # under backup.paths (vaultwarden attachments, forgejo repos, etc)
    # are read live by restic and can be captured mid-write. The fix is
    # a btrfs snapshot of the @data subvolume (mounted at /var/lib on
    # jet) taken before restic runs: snapshot in backupPrepareCommand,
    # point restic paths at it, delete it in backupCleanupCommand.
    # Requires a @snapshots subvolume on jet (spike/ein have one).
    #
    # `host` is the machine the service runs on. It defaults to this
    # host, so a co-located service needs no field. Routing layers
    # (caddy, cloudflared, tailscale-http, backup) only act on services
    # whose host matches this machine; gatus and glance consume every
    # entry, resolving the address through var.network.addrOf.
    options.serviceRegistry = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = config.var.hostname;
          };
          port = lib.mkOption {type = lib.types.port;};
          servePort = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
          };
          expose = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                subdomain = lib.mkOption {type = lib.types.str;};
                basicAuth = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
            });
            default = null;
          };
          backup = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule {
              options = {
                paths = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [];
                };
                database = lib.mkOption {
                  type = lib.types.nullOr (lib.types.submodule {
                    options = {
                      type = lib.mkOption {
                        type = lib.types.enum ["postgres" "sqlite"];
                      };
                      name = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                      path = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                    };
                  });
                  default = null;
                };
              };
            });
            default = null;
          };
          monitor = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                interval = lib.mkOption {
                  type = lib.types.str;
                  default = "5m";
                };
                failureThreshold = lib.mkOption {
                  type = lib.types.int;
                  default = 2;
                };
                successThreshold = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                };
                http = lib.mkOption {
                  type = lib.types.nullOr (lib.types.submodule {
                    options = {
                      path = lib.mkOption {
                        type = lib.types.str;
                        default = "/";
                      };
                      conditions = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = ["[STATUS] == 200"];
                      };
                    };
                  });
                  default = null;
                };
                tcp = lib.mkOption {
                  type = lib.types.nullOr (lib.types.submodule {
                    options.conditions = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = ["[CONNECTED] == true"];
                    };
                  });
                  default = null;
                };
                dns = lib.mkOption {
                  type = lib.types.nullOr (lib.types.submodule {
                    options = {
                      queryType = lib.mkOption {
                        type = lib.types.str;
                        default = "A";
                      };
                      queryName = lib.mkOption {
                        type = lib.types.str;
                        default = "example.com";
                      };
                      conditions = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = ["[DNS_RCODE] == NOERROR"];
                      };
                    };
                  });
                  default = null;
                };
              };
            };
            default = {};
          };
          homepage = lib.mkOption {
            type = lib.types.submodule {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                title = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                icon = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };
              };
            };
            default = {};
          };
        };
      }));
      default = {};
    };

    config.assertions =
      lib.mapAttrsToList (name: svc: {
        assertion = svc.host == config.var.hostname || svc.expose == null;
        message = "serviceRegistry.${name}: expose is set but host is '${svc.host}', not this machine";
      })
      config.serviceRegistry
      ++ lib.mapAttrsToList (name: svc: {
        assertion = lib.elem svc.host fleetHosts;
        message = "serviceRegistry.${name}: host '${svc.host}' is not a known host";
      })
      config.serviceRegistry
      ++ lib.mapAttrsToList (name: svc: let
        probeCount =
          lib.count (p: p != null)
          [svc.monitor.http svc.monitor.tcp svc.monitor.dns];
      in {
        assertion = !svc.monitor.enable || probeCount == 1;
        message = "serviceRegistry.${name}: monitor.enable requires exactly one probe (http, tcp, or dns), got ${toString probeCount}";
      })
      config.serviceRegistry;
  };
}
