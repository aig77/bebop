{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
  # inherit (config.stylix) colors;
in {
  flake.modules.nixos.niri = _: {
    programs.niri.enable = true;
    home-manager.users.${username}.imports = [hm.niri];
  };

  flake.modules.homeManager.niri = {
    pkgs,
    var,
    ...
  }: let
    sessionVariables = {
      TERMINAL = var.terminal;
      BROWSER = var.browser;
      FILE_MANAGER = var.fileManager;
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      XCURSOR_SIZE = "24";
    };
  in {
    home = {
      inherit sessionVariables;
      packages = with pkgs; [
        playerctl
        brightnessctl
        hyprpolkitagent
      ];
    };

    systemd.user = {inherit sessionVariables;};

    wayland.windowManager.niri = {
      enable = true;
      settings = {
        input.keyboard.xkb = {
          layout = "us";
        };

        prefer-no-csd = {};

        _children = [
          {"spawn-at-startup" = {_args = ["hyprpolkitagent"];};}
          {"spawn-at-startup" = {_args = ["playerctld"];};}
          {
            "window-rule" = {
              _children = [
                {"geometry-corner-radius" = {_args = [12];};}
                {"clip-to-geometry" = {_args = [true];};}
              ];
            };
          }
        ];

        layout = {
          focus-ring.off = {};
          border.off = {};
        };

        binds = {
          # Apps
          "Mod+Return".spawn = [var.terminal];
          "Mod+Space".spawn-sh = "noctalia msg panel-toggle launcher";
          "Ctrl+Alt+L".spawn-sh = "noctalia msg session lock";

          # Screenshots
          "Print".screenshot = {};
          "Shift+Print".screenshot-screen = {};
          "Ctrl+Print".screenshot-window = {};

          # Window management
          "Mod+Q".close-window = {};
          "Mod+Shift+Q".quit = {};
          "Mod+T".toggle-window-floating = {};
          "Mod+F".maximize-column = {};
          "Mod+M".toggle-windowed-fullscreen = {};
          "Mod+Tab".focus-column-right = {};
          "Mod+Shift+Tab".focus-column-left = {};

          # Focus
          "Mod+H".focus-column-left = {};
          "Mod+L".focus-column-right = {};
          "Mod+J".focus-window-down = {};
          "Mod+K".focus-window-up = {};

          # Move windows
          "Mod+Shift+H".move-column-left = {};
          "Mod+Shift+L".move-column-right = {};
          "Mod+Shift+J".move-window-down = {};
          "Mod+Shift+K".move-window-up = {};

          # Column layout
          "Mod+bracketright".switch-preset-column-width = {};
          "Mod+bracketleft".switch-preset-column-width-back = {};
          "Mod+comma".consume-or-expel-window-right = {};

          # Workspaces 1-10
          "Mod+1".focus-workspace._args = [1];
          "Mod+2".focus-workspace._args = [2];
          "Mod+3".focus-workspace._args = [3];
          "Mod+4".focus-workspace._args = [4];
          "Mod+5".focus-workspace._args = [5];
          "Mod+6".focus-workspace._args = [6];
          "Mod+7".focus-workspace._args = [7];
          "Mod+8".focus-workspace._args = [8];
          "Mod+9".focus-workspace._args = [9];
          "Mod+0".focus-workspace._args = [10];
          "Mod+Shift+1".move-window-to-workspace._args = [1];
          "Mod+Shift+2".move-window-to-workspace._args = [2];
          "Mod+Shift+3".move-window-to-workspace._args = [3];
          "Mod+Shift+4".move-window-to-workspace._args = [4];
          "Mod+Shift+5".move-window-to-workspace._args = [5];
          "Mod+Shift+6".move-window-to-workspace._args = [6];
          "Mod+Shift+7".move-window-to-workspace._args = [7];
          "Mod+Shift+8".move-window-to-workspace._args = [8];
          "Mod+Shift+9".move-window-to-workspace._args = [9];
          "Mod+Shift+0".move-window-to-workspace._args = [10];

          # Noctalia shell
          "Mod+C".spawn-sh = "noctalia msg panel-toggle control-center";
          "Mod+V".spawn-sh = "noctalia msg panel-toggle clipboard";
          "Mod+O".spawn-sh = "noctalia msg settings-toggle";
          "Mod+P".spawn-sh = "noctalia msg panel-toggle session";

          # Resize columns
          "Mod+Right".switch-preset-column-width = {};
          "Mod+Left".switch-preset-column-width-back = {};

          # Media keys
          "XF86AudioRaiseVolume" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          };
          "XF86AudioLowerVolume" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          };
          "XF86AudioMute" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };
          "XF86AudioMicMute" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
          "XF86MonBrightnessUp" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "brightnessctl -e4 -n2 set 5%+";
          };
          "XF86MonBrightnessDown" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "brightnessctl -e4 -n2 set 5%-";
          };
          "XF86AudioNext" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "playerctl next";
          };
          "XF86AudioPause" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "playerctl play-pause";
          };
          "XF86AudioPlay" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "playerctl play-pause";
          };
          "XF86AudioPrev" = {
            _props.allow-when-locked = true;
            "spawn-sh" = "playerctl previous";
          };
        };
      };
    };
  };
}
