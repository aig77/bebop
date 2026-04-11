{lib, ...}: {
  flake.modules.darwin.base = {
    options.var = lib.mkOption {
      type = lib.types.submodule {
        options = {
          username = lib.mkOption {type = lib.types.str;};
          hostname = lib.mkOption {type = lib.types.str;};
          shell = lib.mkOption {type = lib.types.enum ["zsh" "fish"];};
          terminal = lib.mkOption {
            type = lib.types.str;
            default = "ghostty";
          };
          browser = lib.mkOption {
            type = lib.types.str;
            default = "zen";
          };
        };
      };
      default = {};
    };
  };
}
