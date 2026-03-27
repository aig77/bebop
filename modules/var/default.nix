{lib, ...}: {
  flake.modules.nixos.base = {
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
          location = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          launcher = lib.mkOption {
            type = lib.types.str;
            default = "fuzzel";
          };
          fileManager = lib.mkOption {
            type = lib.types.str;
            default = "nautilus";
          };
          lock = lib.mkOption {
            type = lib.types.str;
            default = "hyprlock";
          };
wallpaperEngine = lib.mkOption {
            type = lib.types.str;
            default = "swww";
          };
          wallpaperPath = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/.cache/bebop/current-wallpaper";
          };
        };
      };
      default = {};
    };
  };
}
