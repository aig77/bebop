{lib, ...}: {
  flake.modules.darwin.base = {
    options.var = lib.mkOption {
      type = lib.types.submodule ({config, ...}: {
        options = {
          username = lib.mkOption {type = lib.types.str;};
          hostname = lib.mkOption {type = lib.types.str;};
          home = lib.mkOption {
            type = lib.types.str;
            default = "/Users/${config.username}";
          };
          repoPath = lib.mkOption {
            type = lib.types.str;
            default = "/Users/${config.username}/.config/bebop";
          };
          shell = lib.mkOption {type = lib.types.enum ["zsh" "fish"];};
        };
      });
      default = {};
    };
  };
}
