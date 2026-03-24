_: {
  flake.modules.homeManager.swww = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (config.lib.stylix) colors;
    wallpaper = ../../assets/wallpapers/Faye-Valentine-Wallpaper-Catppuccin.jpg;

    swww-start = pkgs.writeShellScript "swww-start" ''
      runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      until [ -S "$runtime/wayland-0" ] || [ -S "$runtime/wayland-1" ]; do
        sleep 0.1
      done
      exec ${pkgs.swww}/bin/swww-daemon
    '';

    swww-set-wallpaper = pkgs.writeShellScript "swww-set-wallpaper" ''
      until ${pkgs.swww}/bin/swww query; do sleep 0.1; done
      cache="$HOME/.cache/bebop/last-wallpaper"
      if [ -f "$cache" ] && [ -r "$cache" ]; then
        target="$(cat "$cache")"
        [ -f "$target" ] || target="${wallpaper}"
      else
        target="${wallpaper}"
      fi
      exec ${pkgs.swww}/bin/swww img \
        --transition-type grow \
        --transition-pos "0.5,0.5" \
        --transition-duration 1.5 \
        --transition-fps 60 \
        "$target"
    '';

    random-icon = pkgs.writeText "random.svg" ''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
        <rect width="100" height="100" rx="8" fill="#${colors.base03}"/>
        <text x="50" y="76" font-size="72" text-anchor="middle"
              fill="#${colors.base05}" font-family="sans-serif" font-weight="bold">?</text>
      </svg>
    '';

    wallpaper-picker-theme = pkgs.writeText "wallpaper-picker.rasi" ''
      * {
        bg: #${colors.base00}99;
        ac: #${colors.base0D}ff;
        bo: #${colors.base04}ff;
        fg: #${colors.base05}ff;
      }
      window {
        background-color: @bg;
        border:           2px;
        border-color:     @bo;
        border-radius:    12px;
        width:            720px;
        height:           580px;
        location:         center;
        anchor:           center;
        x-offset:         0;
        y-offset:         0;
      }
      mainbox  { background-color: transparent; padding: 10px; spacing: 8px; }
      inputbar { background-color: transparent; padding: 4px 8px; spacing: 0; text-color: @fg; }
      prompt         { enabled: false; }
      case-indicator { enabled: false; }
      entry    {
        background-color:  transparent;
        text-color:        @fg;
        placeholder:       "Search...";
        placeholder-color: @bo;
      }
      listview {
        padding:          8px;
        spacing:          8px;
        enabled:          true;
        columns:          4;
        cycle:            true;
        dynamic:          true;
        scrollbar:        false;
        layout:           vertical;
        reverse:          false;
        fixed-height:     true;
        fixed-columns:    true;
        cursor:           default;
        background-color: transparent;
      }
      element {
        background-color: transparent;
        padding:          0px;
        orientation:      vertical;
        cursor:           pointer;
      }
      element selected {
        background-color: #${colors.base0D}40;
        border-radius:    8px;
      }
      element-icon {
        background-color: transparent;
        size:             160px;
      }
      element-text { enabled: false; }
    '';

    wallpaper-picker = pkgs.writeShellScriptBin "wallpaper-picker" ''
      WALLPAPER_DIR="''${WALLPAPERS:-$HOME/Pictures/Wallpapers}"
      CACHE_FILE="$HOME/.cache/bebop/last-wallpaper"

      if [ ! -d "$WALLPAPER_DIR" ]; then
        notify-send "Wallpaper Picker" "$WALLPAPER_DIR not found"
        exit 1
      fi

      {
        printf "Random\0icon\x1f${random-icon}\n"
        while IFS= read -r filepath; do
          printf "%s\0icon\x1f%s\n" "''${filepath##*/}" "$filepath"
        done < <(find "$WALLPAPER_DIR" -maxdepth 1 \
          \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
             -o -iname "*.webp" -o -iname "*.gif" \) | sort)
      } | ${pkgs.rofi}/bin/rofi \
          -dmenu \
          -show-icons \
          -p "" \
          -i \
          -theme ${wallpaper-picker-theme} | {
        read -r selected
        [ -z "$selected" ] && exit 0

        if [ "$selected" = "Random" ]; then
          mapfile -t imgs < <(find "$WALLPAPER_DIR" -maxdepth 1 \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.webp" -o -iname "*.gif" \))
          [ ''${#imgs[@]} -eq 0 ] && exit 1
          target="''${imgs[$RANDOM % ''${#imgs[@]}]}"
        else
          target="$WALLPAPER_DIR/$selected"
        fi

        mkdir -p "$(dirname "$CACHE_FILE")"
        printf "%s" "$target" > "$CACHE_FILE"
        ${pkgs.swww}/bin/swww img \
          --transition-type grow \
          --transition-pos "0.5,0.5" \
          --transition-duration 1.5 \
          --transition-fps 60 \
          "$target"
      }
    '';
  in {
    home.packages = [pkgs.swww wallpaper-picker];

    systemd.user.services.swww = {
      Unit = {
        Description = "swww wallpaper daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        Wants = ["swww-wallpaper.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${swww-start}";
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    systemd.user.services.swww-wallpaper = {
      Unit = {
        Description = "Set wallpaper via swww";
        After = ["swww.service"];
        Requires = ["swww.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${swww-set-wallpaper}";
      };
    };
  };
}
