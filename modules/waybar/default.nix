_: {
  flake.modules.homeManager.waybar = {
    lib,
    config,
    pkgs,
    ...
  }: let
    scheme = config.lib.stylix.colors.withHashtag;
  in {
    home.packages = [pkgs.cava];

    programs.waybar = {
      enable = true;
      settings.mainBar = {
        reload_style_on_change = true;

        "group/hyprlandNav" = {
          orientation = "horizontal";
          modules = ["hyprland/workspaces" "hyprland/window"];
        };

        "hyprland/workspaces" = {
          persistent-workspaces = {
            eDP-1 = [1 2 3 4 5 6 7 8];
          };
          on-click = "activate";
          sort-by-number = true;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "6" = "";
            "7" = "";
            "8" = "";
          };
        };

        "hyprland/window" = {
          format = " {title}";
          max-length = 50;
          separate-outputs = true;
        };

        "group/niriNav" = {
          orientation = "horizontal";
          modules = ["niri/workspaces" "niri/window"];
        };

        "niri/workspaces" = {
          persistent-workspaces = {
            eDP-1 = [1 2 3 4];
          };
          on-click = "activate";
          sort-by-number = true;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
          };
        };

        "niri/window" = {
          format = " {title}";
          max-length = 50;
          separate-outputs = true;
        };

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 18;
          spacing = 0;
          all-outputs = true;
          on-click = "activate";
          on-click-right = "close";
        };

        "clock" = {
          format = "{:%H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            on-click-right = "mode";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        "cava" = {
          hide_on_silence = true;
          bars = 12;
          bar_delimiter = 0;
          input_delay = 2;
          sleep_timer = 5;
        };

        "group/hardware" = {
          orientation = "horizontal";
          modules = ["disk" "cpu" "memory"];
        };

        "disk" = {format = "{percentage_used}%  /";};

        "cpu" = {
          format = "{usage}%  /";
          interval = 2;
        };

        "memory" = {
          format = "{percentage}%  ";
          interval = 2;
        };

        "group/systray" = {
          orientation = "horizontal";
          modules = ["network" "bluetooth" "battery"];
        };

        "network" = {
          format-wifi = "{icon}";
          format-ethernet = "";
          format-disconnected = "";
          format-icons = ["" "" "" "" ""];
          tooltip-format = "{ifname} via {gwaddr} ";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          tooltip-format-ethernet = "{ifname} ";
          tooltip-format-disconnected = "Disconnected";
          interval = 10;
          max-length = 50;
          on-click = "nm-connection-editor";
        };

        "bluetooth" = {
          format = "";
          format-disabled = "";
          format-connected = "";
          tooltip-format = "{controller_alias}\t{controller_address}\t{num_connections} connected";
          tooltip-format-connected = ''
            {controller_alias}\t{controller_address}

            {device_enumerate}'';
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "battery" = {
          interval = 2;
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-icons = ["" "" "" "" ""];
          format-charging = "";
          format-full = "";
          tooltip = true;
          tooltip-format = "{capacity}% | {timeTo}";
          max-length = 25;
        };

        "wireplumber" = {
          format = "{volume}% {icon}";
          format-muted = "";
          scroll-step = 5.0;
          on-click = "pavucontrol";
          on-click-right = "qpwgraph";
          format-icons = ["" "" ""];
        };

        "custom/exit" = {
          format = "";
          on-click = "wlogout";
          tooltip = false;
        };
      };

      style = lib.mkForce ''
        @define-color background ${scheme.base06};
        @define-color workspacesbackground1 ${scheme.base00};
        @define-color workspacesbackground2 ${scheme.base00};
        @define-color workspacesbackground3 ${scheme.base01};
        @define-color bordercolor ${scheme.base06};
        @define-color textcolor1 ${scheme.base00};
        @define-color textcolor2 ${scheme.base06};
        @define-color textcolor3 ${scheme.base0B};
        @define-color textcolor4 ${scheme.base0D};
        @define-color textcolor5 ${scheme.base0F};
        @define-color iconcolor ${scheme.base03};

        * {
            font-family: JetBrainsMono Nerd Font, DejaVu Sans, DejaVu Serif;
            border: none;
            border-radius: 0px;
            font-size: 11px;
        }

        window#waybar {
            background-color: transparent;
            opacity: 0.95;
            transition-property: background-color;
            transition-duration: .5s;
        }

        #navigation {
          background-color: @background;
          margin: 4px 0px 4px 10px;
          color: @textcolor1;
          border-radius: 15px;
        }

        #workspaces {
            padding-left: 4px;
            color: transparent;
            font-size: 0px;
        }

        #workspaces button {
            padding: 0px;
            margin: 4px;
            border-radius: 20px;
            min-height: 0px;
            background-color: @workspacesbackground2;
            transition: all 0.3s ease-in-out;
            opacity: 0.4;
            font-size: 0px;
        }

        #workspaces button.active {
            background: @workspacesbackground2;
            transition: all 0.3s ease-in-out;
            min-width: 25px;
            opacity: 1.0;
        }

        #workspaces button:hover {
            background: @workspacesbackground3;
            opacity: 0.7;
        }

        #window {
            padding-left: 6px;
            padding-right: 10px;
            font-weight: bold;
        }

        window#waybar.empty #window {
            padding: 0px 8px;
        }

        #clock {
            background-color: transparent;
            margin: 4px 5px 4px 0px;
            padding-left: 15px;
            padding-right: 15px;
            border: 1.5px solid @background;
            border-radius: 15px;
            color: @textcolor2;
        }

        #hardware {
            background: transparent;
            margin: 4px 5px 4px 5px;
            border-radius: 15px;
            color: @textcolor2;
        }

        #disk {
            padding-left: 15px;
            padding-right: 2px;
        }

        #cpu {
            padding-left: 2px;
            padding-right: 2.5px;
        }

        #memory {
            padding-left: 2px;
            padding-right: 15px;
        }

        #systray {
            background-color: transparent;
            margin: 4px 5px 4px 5px;
            border: 1.5px solid @background;
            border-radius: 15px;
            color: @textcolor2;
        }

        #network {
            padding-left: 15px;
            padding-right: 10px;
        }

        #bluetooth {
            padding-left: 10px;
            padding-right: 10px;
        }

        #battery {
            padding-left: 7px;
            padding-right: 15px;
        }

        #battery.warning { color: orange; }
        #battery.critical { color: red; }

        #wireplumber {
            background-color: transparent;
            margin: 4px 17px 4px 1px;
            color: @textcolor2;
        }

        #custom-exit {
            background-color: @background;
            margin: 4px 10px 4px 5px;
            padding-left: 15px;
            padding-right: 10px;
            border-radius: 15px;
            color: @textcolor1;
        }
      '';
    };
  };
}
