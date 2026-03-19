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
      enable = true;
      settings = {
        main = {
          terminal = "${pkgs.${var.terminal}}/bin/${var.terminal}";
          width = 50;
          lines = 10;
          horizontal-pad = 32;
          vertical-pad = 16;
          inner-pad = 12;
          layer = "overlay";
          font = lib.mkForce "${config.stylix.fonts.monospace.name}:size=14";
          icons-enabled = true;
          launch-prefix = "";
          line-height = 25;
          filter-desktop = true;
          prompt = ''"󰍉 "'';
        };

        colors = {
          background = lib.mkForce "${colors.base00}99";
        };

        border = {
          width = 2;
          radius = 12;
        };
      };
    };
  };
}
