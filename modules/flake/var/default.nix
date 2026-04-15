{lib, ...}: {
  flake.modules.nixos.base = {
    options.var = lib.mkOption {
      type = lib.types.submodule {
        options = {
          username = lib.mkOption {type = lib.types.str;};
          hostname = lib.mkOption {type = lib.types.str;};
          shell = lib.mkOption {
            type = lib.types.enum ["zsh" "fish"];
            default = "zsh";
          };
          terminal = lib.mkOption {
            type = lib.types.enum ["alacritty" "ghostty"];
            default = "ghostty";
          };
          browser = lib.mkOption {
            type = lib.types.enum ["zen"];
            default = "zen";
          };
          location = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          launcher = lib.mkOption {
            type = lib.types.enum ["fuzzel" "quickshell" "rofi"];
            default = "fuzzel";
          };
          fileManager = lib.mkOption {
            type = lib.types.enum ["nautilus" "thunar"];
            default = "thunar";
          };
          lock = lib.mkOption {
            type = lib.types.enum ["hyprlock"];
            default = "hyprlock";
          };
          wallpaperEngine = lib.mkOption {
            type = lib.types.enum ["awww"];
            default = "awww";
          };
          wallpaperPath = lib.mkOption {
            type = lib.types.str;
            default = "$HOME/.cache/bebop/current-wallpaper";
          };
          headless = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      };
      default = {};
    };
  };
}
