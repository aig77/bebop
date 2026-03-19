_: {
  flake.modules.homeManager.rofi = {
    lib,
    config,
    ...
  }: let
    inherit (config.lib.formats.rasi) mkLiteral;
    colors = config.lib.stylix.colors.withHashtag;
    dark = colors.base00;
    light = colors.base07;
    border = colors.base0D;
    selected1 = colors.base0D;
    selected2 = colors.base0E;
    wallpaperPath = "${toString config.stylix.image}";
  in {
    programs.rofi = {
      enable = true;
      theme = lib.mkForce {
        "configuration" = {
          modi = "drun,filebrowser,window,run";
          show-icons = true;
          display-drun = " ";
          display-filebrowser = " ";
          display-window = " ";
          display-run = " ";
          drun-display-format = "{name}";
          window-format = "{w}{t}";
          font = "JetBrainsMono Nerd Font 10";
        };

        "window" = {
          height = mkLiteral "480px";
          width = mkLiteral "720px";
          transparency = "real";
          fullscreen = false;
          enabled = true;
          cursor = "default";
          spacing = mkLiteral "0px";
          padding = mkLiteral "0px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "32px";
          border-color = mkLiteral "${border}";
          background-color = mkLiteral dark;
        };

        "mainbox" = {
          enabled = true;
          spacing = mkLiteral "0px";
          padding = mkLiteral "0px";
          orientation = mkLiteral "vertical";
          children = map mkLiteral ["inputbar" "listbox"];
          background-color = mkLiteral "transparent";
        };

        "inputbar" = {
          enabled = true;
          spacing = mkLiteral "0px";
          padding = mkLiteral "64px";
          children = map mkLiteral ["entry"];
          background-color = mkLiteral "transparent";
          background-image = mkLiteral ''url("${wallpaperPath}", width)'';
        };

        "entry" = {
          border-radius = mkLiteral "24px";
          enabled = true;
          spacing = mkLiteral "0px";
          padding = mkLiteral "16px";
          text-color = mkLiteral "${light}";
          background-color = mkLiteral "${dark}";
        };

        "listbox" = {
          padding = mkLiteral "24px";
          spacing = mkLiteral "0px";
          orientation = mkLiteral "horizontal";
          children = map mkLiteral ["listview" "mode-switcher"];
          background-color = mkLiteral "transparent";
        };

        "listview" = {
          padding = mkLiteral "8px";
          spacing = mkLiteral "8px";
          enabled = true;
          columns = 2;
          cycle = true;
          dynamic = true;
          scrollbar = false;
          layout = mkLiteral "vertical";
          reverse = false;
          fixed-height = true;
          fixed-columns = true;
          cursor = "default";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "${light}";
        };

        "mode-switcher" = {
          orientation = mkLiteral "vertical";
          width = mkLiteral "76px";
          enabled = true;
          padding = mkLiteral "12px";
          spacing = mkLiteral "10px";
          background-color = mkLiteral "transparent";
        };

        "button" = {
          cursor = mkLiteral "pointer";
          border-radius = mkLiteral "40px";
          background-color = mkLiteral "${light}";
          text-color = mkLiteral "${dark}";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        "button selected" = {
          background-color = mkLiteral "${selected2}";
          text-color = mkLiteral "${dark}";
        };

        "element" = {
          enabled = true;
          spacing = mkLiteral "16px";
          padding = mkLiteral "7px";
          border-radius = mkLiteral "20px";
          cursor = mkLiteral "pointer";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "${light}";
        };

        "element selected.normal" = {
          background-color = mkLiteral "${selected1}";
          text-color = mkLiteral "${dark}";
        };

        "element-icon" = {
          size = mkLiteral "38px";
          cursor = mkLiteral "inherit";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
        };

        "element-text" = {
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
          cursor = mkLiteral "inherit";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
        };
      };
    };
  };
}
