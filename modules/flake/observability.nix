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
        };
      };
      default = {};
    };
  };
}
