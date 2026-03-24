_: {
  flake.modules.homeManager.swww = {
    pkgs,
    lib,
    ...
  }: let
    wallpaper = ../../assets/wallpapers/Faye-Valentine-Wallpaper-Catppuccin.jpg;

    swww-start = pkgs.writeShellScript "swww-start" ''
      runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      until [ -S "$runtime/wayland-0" ] || [ -S "$runtime/wayland-1" ]; do
        sleep 0.1
      done
      exec ${lib.getExe pkgs.swww} daemon
    '';

    swww-set-wallpaper = pkgs.writeShellScript "swww-set-wallpaper" ''
      exec ${pkgs.swww}/bin/swww img \
        --transition-type grow \
        --transition-pos "0.5,0.5" \
        --transition-duration 1.5 \
        --transition-fps 60 \
        ${wallpaper}
    '';
  in {
    home.packages = [pkgs.swww];

    systemd.user.services.swww = {
      Unit = {
        Description = "swww wallpaper daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
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
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 0.5";
        ExecStart = "${swww-set-wallpaper}";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
