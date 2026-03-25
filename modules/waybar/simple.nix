_: {
  flake.modules.homeManager.waybarSimple = {
    lib,
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    raw = config.lib.stylix.colors;
    font = config.stylix.fonts.monospace.name;
  in {
    home.packages = [pkgs.cava pkgs.playerctl];

    wayland.windowManager.hyprland.settings.exec-once = lib.mkIf config.wayland.windowManager.hyprland.enable ["waybar" "playerctld"];

    programs.waybar = {
      enable = true;


      settings.pill = {
        layer = "top";
        position = "top";
        height = 56;
        reload_style_on_change = true;
        exclusive = true;

        modules-left = ["group/media"];
        modules-center = ["group/pill"];
        modules-right = ["wlr/taskbar"];

        "group/pill" = {
          orientation = "horizontal";
          modules = [
            "clock"
            "hyprland/workspaces"
            "wireplumber"
            "custom/wallpaper"
            "custom/swaync"
          ];
        };

        "clock" = {
          format = "{:%H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "month";
            on-scroll = 1;
            format = {
              today = "<span color='${colors.base0D}'><b><u>{}</u></b></span>";
            };
          };
        };

        "hyprland/workspaces" = {
          persistent-workspaces."*" = 5;
          on-click = "activate";
          sort-by-number = true;
          format = "";
        };

        "wireplumber" = {
          format = "{icon}";
          format-muted = "󰝟";
          format-icons = ["󰕿" "󰖀" "󰕾"];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume '󰝟 Volume' 'Muted'";
          on-click-right = "pavucontrol";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume '󰕾 Volume' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d%%\", $2 * 100}')\"";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -t 1500 -h string:x-canonical-private-synchronous:volume '󰕿 Volume' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%d%%\", $2 * 100}')\"";
          tooltip = false;
        };

        "group/media" = {
          orientation = "horizontal";
          modules = ["cava" "mpris"];
        };

        "mpris" = {
          player = "playerctld";
          format = "{player_icon}  <span size='small'>{dynamic}</span>";
          format-paused = "⏸  <span size='small'>{dynamic}</span>";
          dynamic-order = ["title" "artist"];
          dynamic-len = 30;
          player-icons.default = "▶";
          status-icons.paused = "⏸";
          tooltip = false;
        };

        "cava" = {
          hide_on_silence = true;
          bars = 12;
          bar_delimiter = 0;
          input_delay = 2;
          format-icons = [
            "<span foreground='#${raw.base0E}'>▁</span>"
            "<span foreground='#${raw.base0D}'>▂</span>"
            "<span foreground='#${raw.base0C}'>▃</span>"
            "<span foreground='#${raw.base0B}'>▄</span>"
            "<span foreground='#${raw.base0A}'>▅</span>"
            "<span foreground='#${raw.base09}'>▆</span>"
            "<span foreground='#${raw.base08}'>▇</span>"
            "<span foreground='#${raw.base08}'>█</span>"
          ];
        };

        "custom/wallpaper" = {
          format = "󰸉";
          on-click = "wallpaper-picker";
          tooltip = false;
        };

        "custom/swaync" = {
          return-type = "json";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
          format = "{icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂚";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
          };
          tooltip = false;
        };

        "tray" = {
          spacing = 8;
          show-passive-items = false;
          icon-size = 16;
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 20;
          spacing = 4;
          on-click = "activate";
          on-click-right = "close";
          on-click-middle = "minimize";
          tooltip-format = "{title}";
          all-outputs = false;
        };
      };

      style = lib.mkForce ''
        * {
          font-family: "${font}", "Symbols Nerd Font Mono";
          font-size: 15px;
          border: none;
          border-radius: 0;
          min-height: 0;
          box-shadow: none;
          text-shadow: none;
        }

        window#waybar {
          background: transparent;
          color: ${colors.base05};
        }

        /* ── center pill ─────────────────────────────────────── */

        #pill {
          background-color: alpha(${colors.base00}, 0.92);
          border: 2px solid ${colors.base04};
          border-radius: 100px;
          margin: 10px 0;
          padding: 0 6px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.4), 0 0 0 1px ${colors.base0D}33;
        }

        #clock {
          color: ${colors.base05};
          font-weight: bold;
          padding: 5px 8px 4px 10px;
        }

        #workspaces {
          padding: 0 6px;
        }

        #workspaces button {
          background: transparent;
          border: none;
          padding: 0;
          margin: 0;
          box-shadow: none;
        }

        #workspaces button label {
          background-color: ${colors.base02};
          border-radius: 50%;
          min-width: 16px;
          min-height: 16px;
          font-size: 0;
          padding: 0;
          margin: 9px 5px;
          transition: all 0.2s ease;
        }

        #workspaces button.active label {
          background-color: ${colors.base0D};
          min-width: 36px;
          border-radius: 100px;
        }

        #workspaces button.occupied:not(.active) label {
          background-color: ${colors.base05};
        }

        #workspaces button:hover label {
          background-color: ${colors.base04};
        }

        #wireplumber {
          color: ${colors.base05};
          font-size: 18px;
          padding: 0 10px 0 6px;
        }

        #wireplumber.muted {
          color: ${colors.base03};
        }

        #custom-wallpaper {
          color: ${colors.base0B};
          font-size: 18px;
          padding: 0 6px;
          margin-right: 5px;
        }

        #custom-swaync {
          color: ${colors.base0A};
          padding: 0 10px 0 6px;
        }

        #custom-swaync.dnd-notification,
        #custom-swaync.dnd-none {
          color: ${colors.base03};
        }

        /* ── left: media ─────────────────────────────────────── */

        #media {
          background: transparent;
          border: none;
          padding: 0;
          margin: 0 0 0 10px;
        }

        #mpris {
          background-color: alpha(${colors.base00}, 0.92);
          border: 2px solid ${colors.base04};
          border-radius: 100px;
          color: ${colors.base05};
          padding: 0 12px 0 16px;
          margin: 10px 4px 10px 0;
          box-shadow: 0 4px 20px rgba(0,0,0,0.4), 0 0 0 1px ${colors.base0D}33;
        }

        #cava {
          background-color: alpha(${colors.base00}, 0.92);
          border: 2px solid ${colors.base04};
          border-radius: 100px;
          font-size: 10px;
          letter-spacing: 1px;
          padding: 0 12px 0 8px;
          margin: 10px 0;
          box-shadow: 0 4px 20px rgba(0,0,0,0.4), 0 0 0 1px ${colors.base0D}33;
        }

        /* ── right: taskbar ─────────────────────────────────── */

        #taskbar {
          background-color: alpha(${colors.base00}, 0.92);
          border: 2px solid ${colors.base04};
          border-radius: 100px;
          margin: 10px 10px 10px 0;
          padding: 0 4px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.4), 0 0 0 1px ${colors.base0D}33;
        }

        #taskbar.empty {
          background: transparent;
          border: none;
          box-shadow: none;
          padding: 0;
          min-width: 0;
        }

        #taskbar button {
          background: transparent;
          border: none;
          border-radius: 100px;
          margin: 0 2px;
          padding: 0 6px;
          min-height: 0;
          transition: background-color 0.2s ease;
        }

        #taskbar button.active {
          background-color: ${colors.base02};
        }

        #taskbar button:hover {
          background-color: ${colors.base02};
        }

        /* ── right: tray ─────────────────────────────────────── */

        #tray {
          margin: 10px 10px 10px 0;
        }

        #tray > .needs-attention {
          background-color: ${colors.base08};
          border-radius: 100px;
        }

        /* ── tooltips ────────────────────────────────────────── */

        tooltip {
          background-color: alpha(${colors.base00}, 0.92);
          border: 1px solid ${colors.base04};
          border-radius: 16px;
          padding: 4px;
          box-shadow: 0 4px 20px rgba(0,0,0,0.4), 0 0 0 1px ${colors.base0D}33;
        }

        tooltip label {
          color: ${colors.base05};
          font-size: 13px;
          padding: 6px 12px;
          border-radius: 12px;
        }

        /* ── clock calendar ──────────────────────────────────── */

        calendar {
          background-color: transparent;
          color: ${colors.base05};
          font-size: 15px;
          border-radius: 12px;
          padding: 4px 6px 6px;
        }

        calendar.header {
          background-color: transparent;
          color: ${colors.base0D};
          font-weight: bold;
          border: none;
          border-radius: 0;
          padding: 4px 2px 8px;
        }

        calendar.button {
          background-color: transparent;
          color: ${colors.base0D};
          border: none;
          border-radius: 8px;
          padding: 2px 8px;
          min-height: 0;
        }

        calendar.button:hover {
          background-color: alpha(${colors.base0D}, 0.15);
        }

        calendar:selected {
          background-color: ${colors.base0D};
          color: ${colors.base00};
          border-radius: 8px;
          font-weight: bold;
        }


        calendar.othermonth {
          color: ${colors.base03};
        }

        calendar.weekend {
          color: ${colors.base0E};
        }
      '';
    };
  };
}
