_: {
  flake.modules.nixos.base = {
    lib,
    config,
    ...
  }: let
    # Order matters: since a port is derived from its list position,
    # append new names at the end to avoid shifting existing ports.
    mkPortGroup = {
      base,
      names,
    }:
      assert lib.assertMsg (lib.length (lib.unique names) == lib.length names)
      "port group has duplicate names: ${toString names}";
      assert lib.assertMsg (!(lib.elem "base" names))
      "'base' is reserved in a port group";
      assert lib.assertMsg (base + lib.length names - 1 <= 65535)
      "port group starting at ${toString base} overflows the port range";
        lib.mkOption {
          default = {};
          type = lib.types.submodule ({config, ...}: {
            options =
              {
                base = lib.mkOption {
                  type = lib.types.port;
                  default = base;
                  description = "Starting port for this group.";
                };
              }
              // lib.listToAttrs (lib.imap0 (i: name:
                lib.nameValuePair name (lib.mkOption {
                  type = lib.types.port;
                  default = config.base + i;
                  description = "Port for ${name} (base + ${toString i}).";
                }))
              names);
          });
        };
  in {
    # TODO: make ports a per-host registry instead of a global one.
    # Replace these per-port mkOptions with:
    #   options.ports = lib.mkOption {
    #     type = lib.types.attrsOf lib.types.port;
    #     default = {};
    #   };
    # Then declare values per host: jet/ports.nix (forgejo, vaultwarden,
    # prometheus, nodeExporter, blockyHttp, etc) and ed/ports.nix
    # (prometheus, nodeExporter, blockyHttp for prometheus-client).
    # jet's prometheus feature scrapes ed's exporters, so jet must also
    # declare nodeExporter + blockyHttp. Missing registration fails loud
    # at eval instead of silently using a global default.
    options.ports = {
      glance = lib.mkOption {
        type = lib.types.port;
        default = 3000;
      };
      arr = mkPortGroup {
        base = 3010;
        names = [
          "jellyfin"
          "sonarr"
          "radarr"
          "prowlarr"
          "bazarr"
          "jellyseerr"
          "sabnzbd"
          "transmission"
          "transmissionPeer"
        ];
      };
      n8n = lib.mkOption {
        type = lib.types.port;
        default = 3020;
      };
      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3030;
      };
      gatus = lib.mkOption {
        type = lib.types.port;
        default = 3040;
      };
      prometheus = mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      dailyStoic = lib.mkOption {
        type = lib.types.port;
        default = 3060;
      };
      vaultwarden = lib.mkOption {
        type = lib.types.port;
        default = 3070;
      };
      actualBudget = lib.mkOption {
        type = lib.types.port;
        default = 3080;
      };
      subtrakr = lib.mkOption {
        type = lib.types.port;
        default = 3090;
      };
      # this stays at 4000 no matter what
      blockyHttp = lib.mkOption {
        type = lib.types.port;
        default = 4000;
      };
      open-webui = lib.mkOption {
        type = lib.types.port;
        default = 4010;
      };
      searx = lib.mkOption {
        type = lib.types.port;
        default = 4020;
      };
      forgejo = lib.mkOption {
        type = lib.types.port;
        default = 4030;
      };
      dbgate = lib.mkOption {
        type = lib.types.port;
        default = 4040;
      };
      unbound = lib.mkOption {
        type = lib.types.port;
        default = 5335;
      };
    };

    config.assertions = let
      entries =
        lib.collect (e: e ? id)
        (lib.mapAttrsRecursive (path: port: {
            inherit port;
            id = lib.concatStringsSep "." path;
            leaf = lib.last path;
          })
          config.ports);

      # "base" mirrors a group's first port, so it would always collide with it
      ports = lib.filter (e: e.leaf != "base") entries;

      collisions = lib.filterAttrs (_: es: lib.length es > 1) (lib.groupBy (e: toString e.port) ports);
    in [
      {
        assertion = collisions == {};
        message =
          "Port collisions: "
          + lib.concatStringsSep "; " (lib.mapAttrsToList
            (port: es: "${port} <- ${lib.concatMapStringsSep ", " (e: e.id) es}")
            collisions);
      }
    ];
  };
}
