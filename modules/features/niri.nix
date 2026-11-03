{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.niri = {pkgs, ...}: {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
      useNautilus = false;
    };

    home-manager.users.${username}.imports = [hm.niri];
  };

  flake.modules.homeManager.niri = {
    config,
    lib,
    pkgs,
    var,
    ...
  }: let
    c = config.lib.stylix.colors;

    sessionVariables = {
      TERMINAL = "ghostty";
      BROWSER = "zen";
      FILE_MANAGER = "thunar";
      NIRI_GAME_WORKSPACE = "games";
    };

    # Niri matches outputs by connector name or by the full make/model/serial
    # string. Prefer the hardware identity so the rule survives port changes.
    monitorName = m: let
      hardware = "${m.make} ${m.model} ${m.serial}";
    in
      if m.make != null && m.model != null && m.serial != null
      then hardware
      else if m.name != null
      then m.name
      else throw "Niri monitor entry needs a name or complete make/model/serial";

    monitorOutputs =
      map (m: {
        output = {
          _args = [(monitorName m)];
          # Omitting the refresh rate makes Niri choose the highest refresh for
          # this resolution. Omitting scale/position lets Niri auto-configure
          # like Hyprland's scale=auto and position=auto.
          mode = "${toString m.width}x${toString m.height}";
        };
      })
      var.monitors;

    workspaceBinds = lib.mergeAttrsList (lib.concatMap (i: let
      key =
        if i == 10
        then "0"
        else toString i;
    in [
      {
        "Super+${key}".focus-workspace = i;
      }
      {
        "Super+Shift+${key}".move-window-to-workspace = i;
      }
    ]) (lib.range 1 10));
  in {
    home = {
      inherit sessionVariables;
      packages = with pkgs; [
        polkit_gnome
        playerctl
        brightnessctl
      ];
    };

    systemd.user = {inherit sessionVariables;};

    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      systemd.enable = true;
      checkConfig = true;
      # The NixOS module owns the portal setup; avoid a duplicate HM portal.
      portalPackage = null;
      xwaylandSatellitePackage = pkgs.xwayland-satellite;

      # Noctalia writes noctalia.kdl. Predeclare the optional include so its
      # apply hook does not try to modify the read-only Nix-managed config.
      extraConfig = lib.mkBefore ''
        include optional=true "~/.config/niri/noctalia.kdl"
      '';

      settings = {
        prefer-no-csd = {};
        hotkey-overlay.skip-at-startup = {};
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        environment = {
          inherit (sessionVariables) TERMINAL BROWSER FILE_MANAGER;
          NIXOS_OZONE_WL = "1";
          MOZ_ENABLE_WAYLAND = "1";
          QT_QPA_PLATFORM = "wayland";
          GDK_BACKEND = "wayland";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };

        cursor = {
          xcursor-theme = "catppuccin-mocha-dark-cursors";
          xcursor-size = 24;
          hide-after-inactive-ms = 3000;
        };

        input = {
          keyboard.xkb.layout = "us";

          touchpad = {
            tap = {};
            natural-scroll = {};
            dwt = {};
            accel-profile = "flat";
            accel-speed = 0.0;
          };

          mouse = {
            accel-profile = "flat";
            accel-speed = 0.0;
          };

          focus-follows-mouse._props."max-scroll-amount" = "0%";
        };

        layout = {
          gaps = 0;
          center-focused-column = "never";

          default-column-width = {proportion = 1.0;};

          preset-column-widths._children = [
            {proportion = 0.33;}
            {proportion = 0.5;}
            {proportion = 0.66;}
            {proportion = 1.0;}
          ];

          focus-ring.off = {};

          border = {
            on = {};
            width = 1;
            active-color = "#${c.base0D}";
            inactive-color = "#${c.base02}";
            urgent-color = "#${c.base08}";
          };

          shadow.off = {};
        };

        overview = {
          backdrop-color = "#${c.base00}";
          workspace-shadow.off = {};
        };

        blur = {
          passes = 4;
          offset = 3.0;
          noise = 0.02;
          saturation = 1.5;
        };

        animations = {
          window-open = {
            duration-ms = 200;
            curve = "ease-out-expo";
          };
          window-close = {
            duration-ms = 200;
            curve = "ease-out-quad";
          };
          workspace-switch.spring._props = {
            "damping-ratio" = 1.0;
            stiffness = 1000;
            epsilon = 0.0001;
          };
          horizontal-view-movement.spring._props = {
            "damping-ratio" = 1.0;
            stiffness = 800;
            epsilon = 0.0001;
          };
          window-movement.spring._props = {
            "damping-ratio" = 1.0;
            stiffness = 800;
            epsilon = 0.0001;
          };
          window-resize.spring._props = {
            "damping-ratio" = 1.0;
            stiffness = 800;
            epsilon = 0.0001;
          };
        };

        recent-windows = {
          open-delay-ms = 150;
          debounce-ms = 750;

          previews = {
            max-height = 480;
            max-scale = 0.5;
          };

          highlight = {
            active-color = "#${c.base0D}80";
            urgent-color = "#${c.base08}80";
            padding = 8;
            corner-radius = 0;
          };

          binds = {
            "Alt+Tab".next-window = {};
            "Alt+Shift+Tab".previous-window = {};
          };
        };

        binds =
          {
            "Super+grave" = {
              _props.repeat = false;
              toggle-overview = {};
            };

            "Super+Return".spawn = [sessionVariables.TERMINAL];
            "Super+B".spawn = [sessionVariables.BROWSER];
            "Super+Shift+F".spawn = [sessionVariables.FILE_MANAGER];

            "Super+Q" = {
              _props.repeat = false;
              close-window = {};
            };
            "Super+Shift+Q".quit._props."skip-confirmation" = true;

            "Super+T".toggle-window-floating = {};
            "Super+F".fullscreen-window = {};
            "Super+M".maximize-window-to-edges = {};

            "Super+Tab".focus-window-down = {};
            "Super+Shift+Tab".focus-window-up = {};

            "Super+H".focus-column-left = {};
            "Super+J".focus-window-down = {};
            "Super+K".focus-window-up = {};
            "Super+L".focus-column-right = {};

            "Super+Shift+H".move-column-left = {};
            "Super+Shift+J".move-window-down = {};
            "Super+Shift+K".move-window-up = {};
            "Super+Shift+L".move-column-right = {};

            "Super+bracketleft".switch-preset-column-width-back = {};
            "Super+bracketright".switch-preset-column-width = {};
            "Super+backslash".consume-or-expel-window-right = {};

            "Super+right".set-column-width = "+10%";
            "Super+left".set-column-width = "-10%";
            "Super+up".set-window-height = "-10%";
            "Super+down".set-window-height = "+10%";

            "Super+S".focus-workspace = "scratchpad";
            "Super+Shift+S".move-window-to-workspace = "scratchpad";

            "Super+Space".spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
            "Super+C".spawn = ["noctalia" "msg" "panel-toggle" "control-center"];
            "Super+P".spawn = ["noctalia" "msg" "panel-toggle" "session"];
            "Ctrl+Alt+L".spawn = ["noctalia" "msg" "session" "lock"];
            "Super+V".spawn = ["noctalia" "msg" "panel-toggle" "clipboard"];
            "Super+O".spawn = ["noctalia" "msg" "settings-toggle"];

            "Print".spawn = ["noctalia" "msg" "screenshot-region"];
            "Shift+Print".spawn = ["noctalia" "msg" "screenshot-fullscreen"];

            "XF86AudioRaiseVolume" = {
              _props."allow-when-locked" = true;
              spawn-sh = "wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
            };
            "XF86AudioLowerVolume" = {
              _props."allow-when-locked" = true;
              spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"];
            };
            "XF86AudioMute" = {
              _props."allow-when-locked" = true;
              spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];
            };
            "XF86AudioMicMute" = {
              _props."allow-when-locked" = true;
              spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"];
            };
            "XF86MonBrightnessUp" = {
              _props."allow-when-locked" = true;
              spawn = ["brightnessctl" "-e4" "-n2" "set" "5%+"];
            };
            "XF86MonBrightnessDown" = {
              _props."allow-when-locked" = true;
              spawn = ["brightnessctl" "-e4" "-n2" "set" "5%-"];
            };
            "XF86AudioNext" = {
              _props."allow-when-locked" = true;
              spawn = ["playerctl" "next"];
            };
            "XF86AudioPlay" = {
              _props."allow-when-locked" = true;
              spawn = ["playerctl" "play-pause"];
            };
            "XF86AudioPrev" = {
              _props."allow-when-locked" = true;
              spawn = ["playerctl" "previous"];
            };
          }
          // workspaceBinds;

        _children =
          [
            {workspace._args = ["games"];}
            {workspace._args = ["scratchpad"];}
          ]
          ++ monitorOutputs
          ++ [
            {spawn-at-startup._args = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"];}
            {spawn-at-startup._args = ["playerctld"];}

            # Terminal-only blur.
            {
              window-rule._children = [
                {match._props."app-id" = "^com\\.mitchellh\\.ghostty$";}
                {background-effect.blur = true;}
              ];
            }

            # Floating utility windows.
            {
              window-rule._children = [
                {match._props."app-id" = ".*[Bb]itwarden.*";}
                {open-floating = true;}
                {default-column-width = {fixed = 1000;};}
                {default-window-height = {fixed = 750;};}
                {block-out-from = "screencast";}
              ];
            }
            {
              window-rule._children = [
                {match._props."app-id" = ".*blueman.*";}
                {open-floating = true;}
                {default-column-width = {fixed = 800;};}
                {default-window-height = {fixed = 600;};}
              ];
            }
            {
              window-rule._children = [
                {match._props."app-id" = ".*pavucontrol.*";}
                {open-floating = true;}
                {default-column-width = {fixed = 800;};}
                {default-window-height = {fixed = 600;};}
              ];
            }
            {
              window-rule._children = [
                {match._props."app-id" = "nm-connection-editor";}
                {open-floating = true;}
              ];
            }
            {
              window-rule._children = [
                {match._props.title = "Calculator";}
                {open-floating = true;}
              ];
            }
            {
              window-rule._children = [
                {match._props.title = "^\\(Select what to share\\)$";}
                {open-floating = true;}
                {default-column-width = {fixed = 800;};}
                {default-window-height = {fixed = 600;};}
              ];
            }

            # Steam/Proton games open on the named games workspace. The title
            # exclude skips helper windows with no title.
            {
              window-rule._children = [
                {match._props."app-id" = "^steam_app_";}
                {exclude._props.title = "^$";}
                {open-on-workspace = "games";}
                {open-fullscreen = true;}
              ];
            }
            {
              window-rule._children = [
                {match._props."app-id" = ".*gamescope.*";}
                {open-on-workspace = "games";}
                {open-fullscreen = true;}
              ];
            }
          ];
      };
    };
  };
}
