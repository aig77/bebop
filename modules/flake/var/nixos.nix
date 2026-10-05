{lib, ...}: {
  flake.modules.nixos.base = {
    config,
    fleetHosts,
    ...
  }: {
    options.var = lib.mkOption {
      type = lib.types.submodule ({config, ...}: {
        options = {
          username = lib.mkOption {type = lib.types.str;};
          hostname = lib.mkOption {type = lib.types.str;};
          git = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };
                email = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };
              };
            };
            default = {};
          };
          home = lib.mkOption {
            type = lib.types.str;
            default = "/home/${config.username}";
          };
          repoPath = lib.mkOption {
            type = lib.types.str;
            default = "/home/${config.username}/.config/bebop";
          };
          shell = lib.mkOption {
            type = lib.types.enum ["zsh" "fish"];
            default = "zsh";
          };
          terminal = lib.mkOption {
            type = lib.types.enum ["alacritty" "ghostty"];
            default = "ghostty";
          };
          browser = lib.mkOption {
            type = lib.types.enum ["zen"];
            default = "zen";
          };
          fileManager = lib.mkOption {
            type = lib.types.enum ["thunar"];
            default = "thunar";
          };
          network = lib.mkOption {
            type = lib.types.submodule {
              options = {
                subnet = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                # Address of a fleet host. Every machine is on the tailnet and
                # resolves by MagicDNS, so a remote host is its own name. This
                # host is `localhost`, avoiding a needless tailnet round-trip.
                addrOf = lib.mkOption {
                  type = lib.types.functionTo lib.types.str;
                  default = name:
                    if name == config.hostname
                    then "localhost"
                    else name;
                };
              };
            };
            default = {};
          };
          # TODO: var.services schema improvements:
          # Typed db backups. Add backup.database submodule
          # (enum postgres/sqlite + name/path); backup.nix generates the
          # pg_dump/sqlite3 prepareCommand and appends the dump file to
          # restic paths. Covers invidious, forgejo (postgres), daily-stoic,
          # vaultwarden, subtrakr (sqlite).
          #
          # `host` is the machine the service runs on. It defaults to this
          # host, so a co-located service needs no field. Routing layers
          # (caddy, cloudflared, tailscale-http, backup) only act on services
          # whose host matches this machine; gatus and glance consume every
          # entry, resolving the address through var.network.addrOf.
          services = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (_: {
              options = {
                host = lib.mkOption {
                  type = lib.types.str;
                  default = config.hostname;
                };
                port = lib.mkOption {type = lib.types.port;};
                servePort = lib.mkOption {
                  type = lib.types.nullOr lib.types.port;
                  default = null;
                };
                # Set for public services only. `null` means tailnet-only.
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
                      };
                      prepareCommand = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                      };
                    };
                  });
                  default = null;
                };
                monitor = lib.mkOption {
                  type = lib.types.submodule ({config, ...}: {
                    options = {
                      enable = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                      };
                      type = lib.mkOption {
                        type = lib.types.enum ["http" "tcp"];
                        default = "http";
                      };
                      path = lib.mkOption {
                        type = lib.types.str;
                        default = "/";
                      };
                      conditions = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default =
                          if config.type == "http"
                          then ["[STATUS] == 200"]
                          else ["[CONNECTED] == true"];
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
                    };
                  });
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
        };
      });
      default = {};
    };

    config.assertions =
      # A non-local service cannot be routed by this host's ingress, so a stray
      # `expose` is a configuration error rather than a silent no-op.
      lib.mapAttrsToList (name: svc: {
        assertion = svc.host == config.var.hostname || svc.expose == null;
        message = "var.services.${name}: expose is set but host is '${svc.host}', not this machine";
      })
      config.var.services
      # Catch typos in `svc.host`; the fleet list comes from configurations.nixos.
      ++ lib.mapAttrsToList (name: svc: {
        assertion = lib.elem svc.host fleetHosts;
        message = "var.services.${name}: host '${svc.host}' is not a known host";
      })
      config.var.services;
  };
}
