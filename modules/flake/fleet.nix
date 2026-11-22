{
  config,
  lib,
  ...
}: let
  serviceFields = {
    # Functional grouping. Glance renders one section per category and gatus
    # groups its endpoints by the same name.
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
    # Set false for entries that exist to be monitored or backed up but are
    # not web services (DNS, a database).
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
          # Whether a failure raises an alert. Set to false for services
          # that are nice to have but not worth paging about.
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

  serviceMeta = lib.types.submodule {
    options =
      serviceFields
      // {
        # The NixOS module that provides this service. `base` imports it on
        # whichever host owns the matching port, so service enablement is
        # driven by the port table, not by the host's imports.nix.
        module = lib.mkOption {type = lib.types.deferredModule;};
        # Lets several services share one module without importing it twice.
        # Defaults to the service name.
        moduleKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
  };

  serviceEntry = lib.types.submodule {
    options =
      serviceFields
      // {
        host = lib.mkOption {type = lib.types.str;};
        port = lib.mkOption {type = lib.types.port;};
        servePort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
        };
      };
  };

  # A bound port, or the bound port plus the tailnet HTTPS port it is
  # served on. `https` maps to `serviceRegistry.<name>.servePort`.
  portSpec = lib.types.either lib.types.port (lib.types.submodule {
    options = {
      port = lib.mkOption {type = lib.types.port;};
      https = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
      };
    };
  });

  normalize = v:
    if builtins.isInt v
    then {
      port = v;
      https = null;
    }
    else {
      inherit (v) port https;
    };
in {
  options.fleet = {
    ports = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf portSpec);
      default = {};
      description = "Per-host port table. The host block is the placement; the key is the service name.";
    };
    services = lib.mkOption {
      type = lib.types.attrsOf serviceMeta;
      default = {};
      description = "Fleet-wide service catalogue. Host and port are inferred from fleet.ports.";
    };
    portOf = lib.mkOption {
      type = lib.types.functionTo (lib.types.functionTo lib.types.port);
      description = "fleet.portOf host name: resolve a port from another host's table.";
    };
  };

  config.fleet.portOf = host: name: let
    table = config.fleet.ports.${host} or (throw "fleet.portOf: unknown host '${host}'");
    entry = table.${name} or (throw "fleet.portOf: '${host}' has no port named '${name}'");
  in
    (normalize entry).port;

  config.flake.modules.nixos.base = {
    config,
    fleet,
    fleetHosts,
    fleetHost,
    ...
  }: let
    ownerOf = name: lib.filter (host: builtins.hasAttr name fleet.ports.${host}) (lib.attrNames fleet.ports);
    owners = lib.mapAttrs (name: _: ownerOf name) fleet.services;
    resolved = lib.filterAttrs (name: _: lib.length owners.${name} == 1) fleet.services;

    # Services whose port lives on this host. These are enabled by data:
    # `base` imports their modules directly, so a host does not need to list
    # service features in imports.nix.
    localServiceNames =
      lib.filter (name: builtins.hasAttr name (fleet.ports.${fleetHost} or {}))
      (lib.attrNames fleet.services);

    moduleKeyOf = name: let
      meta = fleet.services.${name};
    in
      if meta.moduleKey != null
      then meta.moduleKey
      else name;

    modulesByKey =
      lib.foldl' (acc: name: acc // {${moduleKeyOf name} = fleet.services.${name}.module;})
      {}
      localServiceNames;

    duplicatePorts = host:
      lib.filterAttrs (_: names: lib.length names > 1)
      (lib.groupBy
        (name: toString (normalize fleet.ports.${host}.${name}).port)
        (lib.attrNames (fleet.ports.${host} or {})));
  in {
    imports = lib.attrValues modulesByKey;

    options = {
      ports = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.port (lib.types.attrsOf lib.types.port));
        default = {};
        description = "Derived from fleet.ports.<hostname>. Feature modules read their bound ports here.";
      };
      serviceRegistry = lib.mkOption {
        type = lib.types.attrsOf serviceEntry;
        default = {};
        description = "Derived fleet registry. Add services to fleet.services and ports to fleet.ports instead.";
      };
    };

    config = {
      ports =
        lib.mapAttrs (_: v: (normalize v).port)
        (fleet.ports.${fleetHost} or {});

      serviceRegistry = lib.mapAttrs (name: meta: let
        host = lib.head owners.${name};
        spec = normalize fleet.ports.${host}.${name};
      in
        {
          inherit host;
          inherit (spec) port;
          servePort = spec.https;
        }
        // builtins.removeAttrs meta ["module" "moduleKey"])
      resolved;

      assertions =
        lib.mapAttrsToList (host: _: {
          assertion = lib.elem host fleetHosts;
          message = "fleet.ports.${host}: not a known host";
        })
        fleet.ports
        ++ lib.concatMap (
          host:
            lib.mapAttrsToList (port: names: {
              assertion = false;
              message = "fleet.ports.${host}: duplicate port ${port} used by ${lib.concatStringsSep ", " names}";
            })
            (duplicatePorts host)
        )
        (lib.attrNames fleet.ports)
        ++ lib.mapAttrsToList (name: hosts: {
          assertion = lib.length hosts == 1;
          message = "fleet.services.${name}: expected exactly one host with a port named '${name}', found [${lib.concatStringsSep " " hosts}]";
        })
        owners
        ++ [
          {
            assertion = config.var.hostname == fleetHost;
            message = "var.hostname is '${config.var.hostname}' but this system is configured as '${fleetHost}'";
          }
        ]
        ++ lib.mapAttrsToList (name: meta: {
          assertion = meta.category != "other";
          message = "fleet.services.${name}: category not set (pick one of AI, Development, Infrastructure, Media, Observability, Productivity)";
        })
        fleet.services
        ++ lib.mapAttrsToList (name: meta: let
          probes = lib.count (p: p != null) [meta.monitor.http meta.monitor.tcp meta.monitor.dns];
        in {
          assertion = !meta.monitor.enable || probes == 1;
          message = "fleet.services.${name}: monitor.enable requires exactly one probe (http, tcp, or dns), got ${toString probes}";
        })
        fleet.services;
    };
  };
}
