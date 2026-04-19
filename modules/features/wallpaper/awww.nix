_: {
  flake.modules.homeManager.awww = {
    pkgs,
    var,
    ...
  }: let
    awww-start = pkgs.writeShellScript "awww-start" ''
      runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      until [ -S "$runtime/wayland-0" ] || [ -S "$runtime/wayland-1" ]; do
        sleep 0.1
      done
      exec ${pkgs.awww}/bin/awww-daemon
    '';

    awww-set-wallpaper = pkgs.writeShellScript "awww-set-wallpaper" ''
      until ${pkgs.awww}/bin/awww query; do sleep 0.1; done
      mkdir -p "$HOME/.cache/bebop"
      saved=$(grep -m1 '^wallpaper' "$HOME/.config/waypaper/config.ini" | cut -d= -f2 | xargs | sed "s|^~|$HOME|")
      if [ -f "$saved" ]; then
        ${pkgs.waypaper}/bin/waypaper --restore
      else
        ${pkgs.waypaper}/bin/waypaper --random
      fi
    '';
  in {
    home.packages = [pkgs.awww];

    home.sessionVariables.CURRENT_WALLPAPER = var.wallpaperPath;

    wayland.windowManager.hyprland.settings.env = [
      "CURRENT_WALLPAPER,${var.wallpaperPath}"
    ];

    systemd.user.services.awww = {
      Unit = {
        Description = "awww wallpaper daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        Wants = ["awww-wallpaper.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${awww-start}";
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    systemd.user.services.awww-wallpaper = {
      Unit = {
        Description = "Set wallpaper via awww";
        After = ["awww.service"];
        Requires = ["awww.service"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${awww-set-wallpaper}";
      };
    };
  };
}
