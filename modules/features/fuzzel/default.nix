_: {
  flake.modules.homeManager.fuzzel = {
    config,
    pkgs,
    lib,
    var,
    ...
  }: let
    inherit (config.lib.stylix) colors;
  in {
    programs.fuzzel = {
      enable = var.launcher == "fuzzel";
      settings = {
        main = {
          terminal = "${pkgs.${var.terminal}}/bin/${var.terminal}";
          width = 60;
          lines = 8;
          horizontal-pad = 40;
          vertical-pad = 20;
          inner-pad = 8;
          layer = "overlay";
          font = lib.mkForce "${config.stylix.fonts.monospace.name}:size=14";
          icons-enabled = true;
          icon-theme = config.stylix.icons.dark;
          launch-prefix = "";
          line-height = 28;
          filter-desktop = true;
          prompt = ''"󰍉 "'';
          anchor = "top";
          y-margin = 480;
          # hide-before-typing = true;
          minimal-lines = true;
        };

        colors = {
          background = lib.mkForce "${colors.base00}cc";
          border = lib.mkForce "${colors.base02}60";
          text = lib.mkForce "${colors.base04}ff";
          input = lib.mkForce "${colors.base05}ff";
          prompt = lib.mkForce "${colors.base03}ff";
          placeholder = lib.mkForce "${colors.base03}ff";
          match = lib.mkForce "${colors.base0D}ff";
          selection = lib.mkForce "${colors.base02}ff";
          selection-text = lib.mkForce "${colors.base05}ff";
          selection-match = lib.mkForce "${colors.base0D}ff";
        };

        border = {
          width = 1;
          radius = 40;
        };
      };
    };
  };
}
