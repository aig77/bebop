{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland = {pkgs, ...}: let
    # Hyprland ships two session entries: plain Hyprland and a UWSM-managed
    # variant. Keep UWSM for proper systemd session handling, but hide the
    # plain entry and present the UWSM one simply as "Hyprland".
    hyprlandUwsmOnly = let
      pkg =
        (pkgs.hyprland.override {
          withUWSM = true;
          enableXWayland = true;
        }).overrideAttrs (old: {
          pname = "hyprland-uwsm-session";

          postInstall =
            (old.postInstall or "")
            + ''
              # Hide the non-UWSM session entry.
              rm -f $out/share/wayland-sessions/hyprland.desktop

              # Rename the UWSM entry. The stock entry launches hyprland.desktop,
              # which no longer exists in the session list, so point UWSM at
              # start-hyprland directly.
              substituteInPlace $out/share/wayland-sessions/hyprland-uwsm.desktop \
                --replace-fail "Name=Hyprland (uwsm-managed)" "Name=Hyprland" \
                --replace-fail "hyprland.desktop" "-- ${pkgs.hyprland}/bin/start-hyprland"
            '';

          passthru =
            (old.passthru or {})
            // {
              providedSessions = ["hyprland-uwsm"];
            };
        });
    in
      pkg
      // {
        # The NixOS Hyprland module applies genFinalPackage, which may call
        # pkg.override and regenerate the stock package. Return pkg directly so
        # the session filtering above survives.
        override = _: pkg;
      };
  in {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = hyprlandUwsmOnly;
    };

    home-manager.users.${username}.imports = [hm.hyprland];
  };

  flake.modules.homeManager.hyprland = {pkgs, ...}: let
    sessionVariables = {
      TERMINAL = "ghostty";
      BROWSER = "zen";
      FILE_MANAGER = "thunar";
      HYPR_GAME_WORKSPACE = 10;
    };
  in {
    home = {
      inherit sessionVariables;
      packages = with pkgs; [
        hyprpolkitagent
        playerctl
        brightnessctl
      ];
    };

    # Mirror session vars into systemd user session so any
    # desktop manager launched Hyprland inherits them
    systemd.user = {inherit sessionVariables;};

    stylix.targets.hyprland.enable = false;

    services.hyprpaper.settings.splash = false;
  };
}
