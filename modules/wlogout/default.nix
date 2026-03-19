_: {
  flake.modules.homeManager.wlogout = {
    config,
    pkgs,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    backgrounddark = colors.base00;
    backgroundlight = colors.base06;
    textcolor1 = colors.base07;
    highlighted = colors.base0A;
    font = config.stylix.fonts.monospace.name;
  in {
    programs.wlogout = {
      enable = true;
      layout = [
        {
          label = "lock";
          action = "hyprlock";
          text = "";
          keybind = "l";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "";
          keybind = "h";
        }
        {
          label = "logout";
          action = "sleep 1; hyprctl dispatch exit";
          text = "";
          keybind = "e";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "";
          keybind = "s";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "";
          keybind = "u";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "";
          keybind = "r";
        }
      ];

      style = ''
        @define-color backgroundlight ${backgroundlight};
        @define-color backgrounddark ${backgrounddark};
        @define-color textcolor1 ${textcolor1};
        @define-color highlighted ${highlighted};

        * {
            font-family: ${font};
            background-image: none;
            transition: 20ms;
        }

        window {
            background-color: rgba(0,0,0,0.7);
        }

        button {
            color: @textcolor1;
            background-color: @backgrounddark;
            border: 2px solid @backgroundlight;
            border-radius: 20px;
            margin: 10px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 25%;
            box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2) 0 6px 20px 0 rgba(0,0,0,0.19);
        }

        button:focus, button:active, button:hover {
            background-color: @backgrounddark;
            border-color: @highlighted;
            outline-style: none;
            margin: 2px;
        }

        #lock {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
        }

        #hibernate {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
        }

        #logout {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
        }

        #shutdown {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
        }

        #suspend {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
        }

        #reboot {
          background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
        }
      '';
    };
  };
}
