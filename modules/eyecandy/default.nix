_: {
  flake.modules.homeManager.eyecandy = {
    lib,
    config,
    pkgs,
    ...
  }: let
    fetchCommand = "${pkgs.krabby}/bin/krabby name umbreon -s --no-title | ${pkgs.fastfetch}/bin/fastfetch --file-raw -";
  in {
    programs = {
      cava = {
        enable = true;
        settings = lib.mkIf (config.lib ? stylix) (
          let
            colors = config.lib.stylix.colors.withHashtag;
            blue = colors.base0D;
            teal = colors.base0C;
            green = colors.base0B;
            yellow = colors.base0A;
            peach = colors.base09;
            red = colors.base08;
            mauve = colors.base0E;
          in {
            color = {
              gradient = lib.mkForce 1;
              gradient_color_1 = lib.mkForce "'${blue}'";
              gradient_color_2 = lib.mkForce "'${teal}'";
              gradient_color_3 = lib.mkForce "'${green}'";
              gradient_color_4 = lib.mkForce "'${yellow}'";
              gradient_color_5 = lib.mkForce "'${peach}'";
              gradient_color_6 = lib.mkForce "'${red}'";
              gradient_color_7 = lib.mkForce "'${red}'";
              gradient_color_8 = lib.mkForce "'${mauve}'";
            };
          }
        );
      };

      fastfetch = {
        enable = true;
        settings = {
          schema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          display = {
            separator = "  │ ";
            color.separator = 245;
          };
          modules = [
            {
              type = "title";
              color = {
                user = "cyan";
                at = "white";
                host = "cyan";
              };
            }
            "separator"
            {
              type = "os";
              key = "";
              keyColor = "red";
              format = "{2} {8}";
            }
            {
              type = "kernel";
              key = "";
              keyColor = "red";
              format = "{2}";
            }
            {
              type = "uptime";
              key = "󰔛";
              keyColor = "red";
              format = "{?1}{1}d {?}{2}h {3}m";
            }
            {
              type = "packages";
              key = "󰏖";
              keyColor = "red";
              format = "{1}";
            }
            {
              type = "display";
              key = "󰍹";
              keyColor = "green";
              format = "{2} @ {3}Hz";
            }
            {
              type = "wm";
              key = "󰖲";
              keyColor = "green";
              format = "{1}";
            }
            {
              type = "shell";
              key = "";
              keyColor = "green";
              format = "{1}";
            }
            {
              type = "terminal";
              key = "󰞷";
              keyColor = "green";
              format = "{1}";
            }
            {
              type = "cpu";
              key = "";
              keyColor = "blue";
              format = "{1}";
            }
            {
              type = "gpu";
              key = "󰢮";
              keyColor = "blue";
              format = "{2}";
              hideType = "integrated";
            }
            {
              type = "memory";
              key = "";
              keyColor = "blue";
              format = "{1} / {2} ({3})";
            }
            {
              type = "disk";
              key = "󰋊";
              keyColor = "blue";
              format = "{1} / {2}";
            }
            {
              type = "colors";
              key = "󰏘";
              keyColor = "yellow";
              symbol = "circle";
            }
          ];
        };
      };

      fish = {
        shellAliases.fetch = fetchCommand;
        interactiveShellInit = ''
          function fish_greeting
            ${fetchCommand}
          end
        '';
      };

      zsh = {
        shellAliases.fetch = fetchCommand;
        initContent = lib.mkBefore ''
          ${fetchCommand}
        '';
      };
    };

    home.packages = with pkgs; [
      krabby
      cmatrix
      pipes-rs
      cbonsai
      tty-clock
      asciiquarium
      lavat
      lolcat
      sl
      nms
    ];
  };
}
