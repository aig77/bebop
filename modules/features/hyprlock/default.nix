_: {
  flake.modules.homeManager.hyprlock = {
    lib,
    config,
    var,
    ...
  }: let
    inherit (config.lib.stylix) colors;
    background = "rgb(${colors.base00})";
    foreground = "rgb(${colors.base06})";
    blue = "rgb(${colors.base0C})";
    red = "rgb(${colors.base0F})";
    wallpaper = var.wallpaperPath;
    font = config.stylix.fonts.monospace.name;
  in {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          hide_cursor = true;
          ignore_empty_input = true;
        };

        background = {
          monitor = "";
          path = wallpaper;
          blur_passes = 2;
          blur_size = 4;
        };

        input-field = lib.mkForce {
          monitor = "";
          size = "200, 50";
          outline_thickness = 3;
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = -1;
          outer_color = foreground;
          inner_color = background;
          font_color = foreground;
          fade_on_empty = true;
          fade_timeout = 1000;
          placeholder_text = "<i>🔒Password...</i>";
          hide_input = false;
          rounding = -1;
          check_color = blue;
          fail_color = red;
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          fail_transition = 300;
          capslock_color = red;
          numlock_color = -1;
          bothlock_color = -1;
          invert_numlock = false;
          swap_font_color = false;
          position = "0, -20";
          halign = "center";
          valign = "center";
        };

        label = [
          {
            monitor = "";
            text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
            color = foreground;
            font_size = 28;
            font_family = font;
            position = "0, 250";
            halign = "center";
            valign = "center";
            shadow_passes = 5;
            shadow_size = 10;
          }
          {
            monitor = "";
            text = ''cmd[update:1000] echo "<span>$(date +"%H:%M")</span>"'';
            color = foreground;
            font_size = 120;
            position = "0, 380";
            halign = "center";
            valign = "center";
          }
          # Caps Lock indicator
          {
            monitor = "";
            text = ''cmd[update:100] if [ "$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1)" = "1" ]; then echo "Caps Lock ON"; fi'';
            color = red;
            font_size = 14;
            font_family = font;
            position = "0, -80";
            halign = "center";
            valign = "center";
          }
          # USER
          {
            monitor = "";
            text = "  $USER";
            color = foreground;
            outline_thickness = 2;
            dots_size = 0.2;
            dots_spacing = 0.2;
            dots_center = true;
            font_size = 18;
            font_family = font;
            position = "0, -180";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
