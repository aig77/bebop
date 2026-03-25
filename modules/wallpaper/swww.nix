_: {
  flake.modules.homeManager.swww = {
    pkgs,
    ...
  }: let
    swww-start = pkgs.writeShellScript "swww-start" ''
      runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      until [ -S "$runtime/wayland-0" ] || [ -S "$runtime/wayland-1" ]; do
        sleep 0.1
      done
      exec ${pkgs.swww}/bin/swww-daemon
    '';

    swww-set-wallpaper = pkgs.writeShellScript "swww-set-wallpaper" ''
      until ${pkgs.swww}/bin/swww query; do sleep 0.1; done
      mkdir -p "$HOME/.cache/bebop"
      saved=$(grep -m1 '^wallpaper' "$HOME/.config/waypaper/config.ini" | cut -d= -f2 | xargs | sed "s|^~|$HOME|")
      if [ -f "$saved" ]; then
        ${pkgs.waypaper}/bin/waypaper --restore
      else
        ${pkgs.waypaper}/bin/waypaper --random
      fi
    '';
  in {
    home.packages = [pkgs.swww];

    home.sessionVariables.CURRENT_WALLPAPER = "$HOME/.cache/bebop/current-wallpaper";

    wayland.windowManager.hyprland.settings.env = [
      "CURRENT_WALLPAPER,$HOME/.cache/bebop/current-wallpaper"
    ];

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
