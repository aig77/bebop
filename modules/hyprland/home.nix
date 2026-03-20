_: {
  flake.modules.homeManager.hyprland = {
    config,
    inputs,
    lib,
    pkgs,
    var,
    ...
  }: let
    inherit (config.lib.stylix) colors;

    launcherCommand =
      if var.launcher == "rofi"
      then "rofi -show drun"
      else var.launcher;

    view-binds = pkgs.writeShellScriptBin "view-binds" ''
      BINDS=$(hyprctl binds -j | ${pkgs.jq}/bin/jq -r '.[] |
        select(.description | length > 0) |
        ((if (.modmask >= 64) then "󰘳 + " else "" end) +
         (if (.modmask % 64 >= 8) then "󰘵 + " else "" end) +
         (if (.modmask % 8 >= 4) then "󰘴 + " else "" end) +
         (if (.modmask % 4 >= 1) then "󰘶 + " else "" end) +
         "\(.key)  ➜  \(.description)")')

      LINE_COUNT=$(echo "$BINDS" | wc -l)

      echo "$BINDS" | ${pkgs.fuzzel}/bin/fuzzel --dmenu \
          --width 35 \
          --lines "$LINE_COUNT" \
          --font "${config.stylix.fonts.monospace.name}:size=10" \
          --anchor right \
          --line-height 20 \
          --x-margin 40 \
          --y-margin 40 \
          --border-width 2 \
          --border-radius 12 \
          --background-color ${colors.base00}dd \
          --text-color ${colors.base05}ff \
          --selection-color ${colors.base02}ff \
          --selection-text-color ${colors.base0D}ff \
          --border-color ${colors.base0D}ff \
          --input-color ${colors.base01}ff \
          --hide-prompt \
    '';
  in {
    home.packages = [pkgs.hyprpolkitagent view-binds];

    services.hyprpaper.settings.splash = false;

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd.variables = ["--all"];
      plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
        hyprfocus
      ];

      settings = {
        exec-once = [
          "systemctl --user start hyprpolkitagent"
        ];

        env = [
          "NIXOS_OZONE_WL,1"
          "MOZ_ENABLE_WAYLAND,1"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "T_QPA_PLATFORM,wayland"
          "GDK_BACKEND,wayland"
          "ELECTRON_OZONE_PLATFORM_HINT,auto"
        ];

        monitor = [",preferred,auto,auto"];

        plugin = {
          hyprfocus.enabled = "yes";
        };

        bindd = [
          "SUPER, slash, View Keybinds, exec, view-binds"

          "SUPER, RETURN, Open Terminal, exec, ${var.terminal}"
          "SUPER, SPACE, Open Launcher, exec, ${launcherCommand}"
          "SUPER, C, Lock Screen, exec, ${var.lock}"
          "SUPER, P, Logout, exec, ${var.logout}"

          ", PRINT, Screenshot Area, exec, screenshot-area"
          "SHIFT, PRINT, Screenshot Screen, exec, screenshot-screen"
          "CTRL, PRINT, Screenshot Window, exec, screenshot-window"

          "SUPER, Q, Kill Active Window, killactive"
          "SUPER SHIFT, Q, Exit Hyprland, exit"
          "SUPER, T, Toggle Floating, togglefloating"
          "SUPER, P, Pseudo Tiling, pseudo"
          "SUPER, O, Toggle Split, togglesplit"
          "SUPER, F, Fullscreen (Internal), fullscreen, 0"
          "SUPER SHIFT, F, Fullscreen (Global), fullscreen, 1"

          "SUPER, H, Move Focus Left, movefocus, l"
          "SUPER, J, Move Focus Down, movefocus, d"
          "SUPER, K, Move Focus Up, movefocus, u"
          "SUPER, L, Move Focus Right, movefocus, r"
          "SUPER SHIFT, H, Move Window Left, movewindow, l"
          "SUPER SHIFT, J, Move Window Down, movewindow, d"
          "SUPER SHIFT, K, Move Window Up, movewindow, u"
          "SUPER SHIFT, L, Move Window Right, movewindow, r"

          "SUPER, tab, Cycle Next Window, cyclenext"

          "SUPER, 1, Switch to Workspace 1, workspace, 1"
          "SUPER, 2, Switch to Workspace 2, workspace, 2"
          "SUPER, 3, Switch to Workspace 3, workspace, 3"
          "SUPER, 4, Switch to Workspace 4, workspace, 4"
          "SUPER, 5, Switch to Workspace 5, workspace, 5"
          "SUPER, 6, Switch to Workspace 6, workspace, 6"
          "SUPER, 7, Switch to Workspace 7, workspace, 7"
          "SUPER, 8, Switch to Workspace 8, workspace, 8"
          "SUPER SHIFT, 1, Move to Workspace 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, Move to Workspace 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, Move to Workspace 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, Move to Workspace 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, Move to Workspace 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, Move to Workspace 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, Move to Workspace 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, Move to Workspace 8, movetoworkspace, 8"

          "SUPER, S, Toggle Special Workspace, togglespecialworkspace, magic"
          "SUPER SHIFT, S, Move to Special Workspace, movetoworkspace, special:magic"
          "SUPER, mouse_down, Next Workspace, workspace, e+1"
          "SUPER, mouse_up, Previous Workspace, workspace, e-1"
        ];

        bindm = [
          "SUPER, mouse:272, movewindow"
          "SUPER, mouse:273, resizewindow"
        ];

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            clickfinger_behavior = true;
          };
          sensitivity = 0;
          force_no_accel = true;
          accel_profile = "flat";
        };

        general = {
          gaps_in = 8;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" =
            lib.mkForce
            "rgb(${colors.base0D}) rgb(${colors.base0E}) rgb(${colors.base0D}) 45deg";
          "col.inactive_border" = lib.mkForce "rgb(${colors.base02})";
          layout = "dwindle";
          allow_tearing = false;
        };

        decoration = {
          rounding = 12;
          active_opacity = 1.0;
          inactive_opacity = 0.92;
          shadow = {
            range = 25;
            render_power = 3;
          };
          blur = {
            enabled = true;
            size = 8;
            passes = 4;
            noise = 0.01;
            contrast = 0.8;
            vibrancy = 0.2;
            new_optimizations = true;
            ignore_opacity = true;
          };
        };

        dwindle = {
          pseudotile = "yes";
          force_split = 2;
          preserve_split = "yes";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          focus_on_activate = true;
        };

        animations = {
          enabled = true;
          bezier = [
            "smoothOut, 0.36, 0, 0.66, -0.56"
            "smoothIn, 0.25, 1, 0.5, 1"
            "overshot, 0.05, 0.9, 0.1, 1.05"
            "softSnap, 0.4, 0, 0.2, 1"
            "fluent, 0.0, 0.0, 0.2, 1.0"
          ];
          animation = [
            "windows, 1, 5, overshot, popin 80%"
            "windowsIn, 1, 5, overshot, popin 80%"
            "windowsOut, 1, 4, smoothOut, popin 90%"
            "windowsMove, 1, 3, softSnap"
            "layersIn, 1, 3, smoothIn, slide"
            "layersOut, 1, 2, softSnap, slide"
            "fade, 1, 4, smoothIn"
            "fadeIn, 1, 4, smoothIn"
            "fadeOut, 1, 4, smoothOut"
            "fadeSwitch, 1, 4, smoothIn"
            "fadeShadow, 1, 4, smoothIn"
            "fadeDim, 1, 4, smoothIn"
            "fadeDpms, 1, 4, smoothIn"
            "workspaces, 1, 5, overshot, slide"
            "specialWorkspace, 1, 5, overshot, slidevert"
          ];
        };

        windowrule = [
          "match:class ^(org.pulseaudio.pavucontrol)$, float on"
          "match:class ^(nm-connection-editor)$, float on"
          "match:class ^(.blueman-manager-wrapped)$, float on"
          "match:title ^(.*Bitwarden Password Manager.*)$, float on"
          "match:title Calculator, float on"
          "match:class ^(steam_app_.*)$, fullscreen on"
          "match:class ^(steam_app_.*)$, workspace 8"
          "match:class ^(gamescope)$, fullscreen on"
          "match:class ^(gamescope)$, workspace 8"
          "match:class ^(zen*)$, match:title ^(.*YouTube.*)$, idle_inhibit focus"
          "match:class ^(zen*)$, idle_inhibit fullscreen"
          "match:title ^(.*Bitwarden Password Manager.*)$, no_screen_share on"
        ];

        layerrule = [
          "blur on, match:namespace bar-0"
          "blur on, match:namespace launcher"
          "ignore_alpha 0.5, match:namespace launcher"
          "blur on, match:namespace rofi"
          "ignore_alpha 0.5, match:namespace rofi"
        ];
      };
    };
  };
}
