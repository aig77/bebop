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
                url = lib.mkOption {type = lib.types.str;};
                sha256 = lib.mkOption {type = lib.types.str;};
                name = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            });
            default = {};
            description = "Dashboards to provision into Grafana via environment.etc";
          };
        };
      };
      default = {};
    };
  };
}
