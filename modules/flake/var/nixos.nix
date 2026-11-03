{lib, ...}: {
  flake.modules.nixos.base = _: {
    options.var = lib.mkOption {
      type = lib.types.submodule ({config, ...}: {
        options = {
          username = lib.mkOption {type = lib.types.str;};
          hostname = lib.mkOption {type = lib.types.str;};
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
          monitors = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                make = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                model = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                serial = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                width = lib.mkOption {type = lib.types.int;};
                height = lib.mkOption {type = lib.types.int;};
                framerate = lib.mkOption {type = lib.types.either lib.types.int lib.types.float;};
                x = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                };
                y = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                };
                scale = lib.mkOption {
                  type = lib.types.float;
                  default = 1.0;
                };
              };
            });
            default = [];
          };
        };
      });
      default = {};
    };

    config.assertions = [];
  };
}
