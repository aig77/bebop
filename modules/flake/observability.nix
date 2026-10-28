{lib, ...}: {
  flake.modules.nixos.base = {
    options.observability = lib.mkOption {
      type = lib.types.submodule {
        options = {
          lokiHost = lib.mkOption {
            type = lib.types.str;
            default = "jet";
          };
          scrapeTargets = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                host = lib.mkOption {type = lib.types.str;};
                job = lib.mkOption {
                  type = lib.types.str;
                  default = "node";
                };
                port = lib.mkOption {
                  type = lib.types.nullOr lib.types.port;
                  default = null;
                };
              };
            });
            default = [];
          };
          grafanaDashboards = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                source = lib.mkOption {
                  type = lib.types.nullOr (lib.types.either lib.types.path lib.types.package);
                  default = null;
                };
                url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                sha256 = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            });
            default = {};
            description = "Grafana dashboards to provision: local source file or remote url+sha256";
          };
        };
      };
      default = {};
    };
  };
}
