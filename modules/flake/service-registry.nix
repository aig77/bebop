{lib, ...}: {
  flake.modules.nixos.base = {
    config,
    fleetHosts,
    ...
  }: {
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
          # Functional grouping. Glance renders one section per category,
          # gatus groups its endpoints by the same name. The value is the
          # section title, so the enum doubles as the display name.
          #
          # Sections are ordered alphabetically, so the enum values are
          # listed in alphabetical order too. "other" is the lowercase
          # fallback: it sorts after every capitalized category and only
          # shows up when a service forgets to pick one (an assertion
          # rejects that).
          category = lib.mkOption {
            type = lib.types.enum [
              "AI"
              "Development"
              "Infrastructure"
              "Media"
              "Observability"
              "Productivity"
              "other"
            ];
            default = "other";
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
          # Route this private service over the tailnet with `tailscale serve`.
          # Set false for entries that exist to be monitored or backed up but
          # are not web services (a database, for instance), where an HTTPS
          # proxy in front of the backend protocol makes no sense. Ignored
          # when `expose` is set, since public exposure goes through Caddy.
          serve = lib.mkOption {
            type = lib.types.bool;
            default = true;
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
                # Whether a failure raises an alert. Set to false for
                # services that are nice to have but not worth paging
                # about; the check still runs and shows on the dashboard.
                alert = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
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
      ++ lib.mapAttrsToList (name: svc: {
        assertion = svc.category != "other";
        message = "serviceRegistry.${name}: category not set (pick one of AI, Development, Infrastructure, Media, Observability, Productivity)";
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
