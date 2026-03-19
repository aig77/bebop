_: {
  flake.modules.homeManager.niri = {
    config,
    pkgs,
    var,
    ...
  }: let
    inherit (config.lib.stylix.colors) base0D base0E;
  in {
    home.packages = [pkgs.swww];

    programs.niri.settings = {
      environment = {
        "NIXOS_OZONE_WL" = "1";
        "MOZ_ENABLE_WAYLAND" = "1";
        "XDG_SESSION_TYPE" = "wayland";
        "T_QPA_PLATFORM" = "wayland";
        "GDK_BACKEND" = "wayland";
        "ELECTRON_OZONE_PLATFORM_HINT" = "auto";
      };

      spawn-at-startup = [
        {command = ["dbus-update-activation-environment" "--systemd" "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"];}
        {
          command = [
            "sh"
            "-c"
            "swww-daemon &"
            "sleep 0.5 && swww img '${config.stylix.image}'"
          ];
        }
        {command = ["waybar"];}
        {command = ["hypridle"];}
        {command = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"];}
      ];

      binds = with config.lib.niri.actions; {
        "Mod+Return".action.spawn = var.terminal;
        "Mod+Space".action.spawn =
          if var.launcher == "rofi"
          then ["rofi" "-show" "drun"]
          else var.launcher;
        "Mod+C".action.spawn = var.lock;

        "Print".action.spawn = "screenshot-area";
        "Shift+Print".action.spawn = "screenshot-screen";
        "Ctrl+Print".action.spawn = "screenshot-window";

        "Mod+Q".action = close-window;
        "Mod+Shift+Q".action = quit;
        "Mod+Tab".action = focus-window-previous;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+T".action = toggle-window-floating;
        "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;
        "Mod+O".action = toggle-overview;
        "Mod+Shift+O".action = switch-preset-column-width;
        "Mod+H".action = focus-column-left;
        "Mod+J".action = focus-window-or-workspace-down;
        "Mod+K".action = focus-window-or-workspace-up;
        "Mod+L".action = focus-column-right;
        "Mod+U".action = focus-workspace-down;
        "Mod+I".action = focus-workspace-up;
        "Mod+Left".action = focus-column-left;
        "Mod+Down".action = focus-window-or-workspace-down;
        "Mod+Up".action = focus-window-or-workspace-up;
        "Mod+Right".action = focus-column-right;
        "Mod+Ctrl+H".action = focus-monitor-left;
        "Mod+Ctrl+J".action = focus-monitor-down;
        "Mod+Ctrl+K".action = focus-monitor-up;
        "Mod+Ctrl+L".action = focus-monitor-right;
        "Mod+Ctrl+Left".action = focus-monitor-left;
        "Mod+Ctrl+Down".action = focus-monitor-down;
        "Mod+Ctrl+Up".action = focus-monitor-up;
        "Mod+Ctrl+Right".action = focus-monitor-right;
        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
        "Mod+Shift+K".action = move-window-up-or-to-workspace-up;
        "Mod+Shift+L".action = move-column-right;
        "Mod+Shift+Left".action = move-column-left;
        "Mod+Shift+Down".action = move-window-down-or-to-workspace-down;
        "Mod+Shift+Up".action = move-window-up-or-to-workspace-up;
        "Mod+Shift+Right".action = move-column-right;
        "Mod+Ctrl+Shift+H".action = move-column-to-monitor-left;
        "Mod+Ctrl+Shift+J".action = move-column-to-monitor-down;
        "Mod+Ctrl+Shift+K".action = move-column-to-monitor-up;
        "Mod+Ctrl+Shift+L".action = move-column-to-monitor-right;
        "Mod+Ctrl+Shift+Left".action = move-column-to-monitor-left;
        "Mod+Ctrl+Shift+Down".action = move-column-to-monitor-down;
        "Mod+Ctrl+Shift+Up".action = move-column-to-monitor-up;
        "Mod+Ctrl+Shift+Right".action = move-column-to-monitor-right;
        "Mod+Ctrl+U".action = move-column-to-workspace-down;
        "Mod+Ctrl+I".action = move-column-to-workspace-up;
        "Mod+WheelScrollUp".action = focus-column-left;
        "Mod+WheelScrollDown".action = focus-column-right;
        "Mod+Shift+WheelScrollUp".action = focus-window-or-workspace-up;
        "Mod+Shift+WheelScrollDown".action = focus-window-or-workspace-down;

        "Mod+BracketLeft".action = consume-or-expel-window-left;
        "Mod+BracketRight".action = consume-or-expel-window-right;
        "Mod+Comma".action = consume-window-into-column;
        "Mod+Period".action = expel-window-from-column;

        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";

        "XF86AudioRaiseVolume".action.spawn = ["pamixer" "--increase" "5"];
        "XF86AudioLowerVolume".action.spawn = ["pamixer" "--decrease" "5"];
        "XF86AudioMute".action.spawn = ["pamixer" "--toggle-mute"];
        "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "+5%"];
        "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;

        "Mod+grave".action = show-hotkey-overlay;
      };

      input = {
        keyboard.xkb.layout = "us";
        focus-follows-mouse.enable = true;
        mouse.accel-profile = "flat";
      };

      window-rules = [
        {
          matches = [];
          clip-to-geometry = true;
          geometry-corner-radius = {
            top-left = 12.0;
            top-right = 12.0;
            bottom-left = 12.0;
            bottom-right = 12.0;
          };
          draw-border-with-background = false;
          border = {
            enable = true;
            width = 2;
            active.gradient = {
              from = "#${base0E}";
              to = "#${base0D}";
              angle = 45;
            };
            inactive.color = "transparent";
            urgent.color = "#9b0000";
          };
        }

        {
          matches = [{title = ".*Calculator.*";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "org.pulseaudio.pavucontrol";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "nm-connection-editor";}];
          open-floating = true;
        }
        {
          matches = [{app-id = "blueman-manager";}];
          open-floating = true;
        }
        {
          matches = [{title = ".*Bitwarden Password Manager.*";}];
          open-floating = true;
          block-out-from = "screencast";
        }

        {
          matches = [{app-id = "steam_app_.*";}];
          open-maximized = true;
        }
        {
          matches = [{app-id = "gamescope";}];
          open-maximized = true;
        }

        {
          matches = [{is-floating = true;}];
          shadow = {
            enable = true;
            softness = 40;
            spread = 5;
            offset.x = 0;
            offset.y = 5;
            draw-behind-window = true;
            color = "#00000070";
          };
        }
      ];

      layout = {
        gaps = 16;
        struts = {
          left = -5;
          right = -5;
          top = 0;
          bottom = 0;
        };
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
        ];
        shadow = {
          enable = true;
          softness = 40;
          spread = 5;
          offset.x = 0;
          offset.y = 5;
          draw-behind-window = true;
          color = "#00000070";
        };
        insert-hint.enable = true;
        center-focused-column = "on-overflow";
      };

      hotkey-overlay.skip-at-startup = true;
    };
  };
}
