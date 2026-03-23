_: {
  flake.modules.homeManager.hyprpanel = {
    inputs,
    osConfig,
    pkgs,
    var,
    ...
  }: {
    programs.hyprpanel = {
      enable = true;
      package = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;

      settings = {
        bar.layouts =
          if (var.hostname != "faye")
          then {
            "0" = {
              "left" = ["dashboard" "workspaces" "windowtitle"];
              "middle" = ["media"];
              "right" = ["systray" "volume" "network" "bluetooth" "notifications" "clock"];
            };
          }
          else {
            "0" = {
              "left" = ["dashboard" "workspaces" "windowtitle"];
              "middle" = ["media"];
              "right" = ["systray" "volume" "notifications" "clock"];
            };
          };

        wallpaper.enable = false;

        theme = {
          font = {
            name = "JetBrainsMono Nerd Font";
            size = "14px";
          };
          bar = {
            floating = true;
            transparent = true;
            border_radius = "0.8em";
            outer_spacing = "0.8em";
            margin_top = "0.2em";
            margin_bottom = "0.2em";
            margin_sides = "0em";
            layer = "top";
            opacity = 95;
            buttons.radius = "1em";
          };
          menus.menu.dashboard.profile = {
            size = "10em";
            radius = "5em";
          };
        };

        bar = {
          launcher.icon = "󱄅";
          workspaces = {
            show_icons = false;
            show_numbered = false;
            monitorSpecific = false;
            workspaces = 8;
          };
          clock = {
            format = "%a, %b %d · %H:%M";
            showIcon = false;
          };
          volume.label = false;
        };

        menus = {
          dashboard = {
            profile.enabled = false;
            quote.enabled = false;
            directories.enabled = false;
            shortcuts.left.shortcut1 = {
              icon = "󰖟";
              command = var.browser;
              tooltip = "Browser";
            };
          };
          clock = {
            military = true;
            weather = {
              enabled = true;
              inherit (var) location;
              key = osConfig.sops.templates."weatherapi.json".path;
              unit = "metric";
            };
          };
        };
      };
    };

    home.file.".face.icon".source = ../hosts/nixos/${var.hostname}/icon.jpg;

    wayland.windowManager.hyprland.settings.exec-once = ["hyprpanel"];
  };
}
