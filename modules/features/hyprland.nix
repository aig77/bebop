{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland = {pkgs, ...}: let
    # Hyprland ships two session entries: plain Hyprland and a UWSM-managed
    # variant. Keep UWSM for proper systemd session handling, but hide the
    # plain entry and present the UWSM one simply as "Hyprland".
    #
    # Wrap the stock package instead of overriding it, so the Hyprland binary
    # still comes from cache.nixos.org and only this tiny wrapper is built.
    hyprlandSession = let
      base =
        pkgs.runCommand "hyprland-session" {
          version = pkgs.hyprland.version;
          passthru = {
            providedSessions = ["hyprland-uwsm"];
          };
        } ''
          mkdir -p $out/share/wayland-sessions

          # Link everything from the stock package except its session directory.
          for entry in ${pkgs.hyprland}/*; do
            name=$(basename "$entry")
            if [ "$name" = "share" ]; then
              mkdir -p $out/share
              for sub in ${pkgs.hyprland}/share/*; do
                subname=$(basename "$sub")
                if [ "$subname" = "wayland-sessions" ]; then
                  continue
                fi
                ln -s "$sub" "$out/share/$subname"
              done
            else
              ln -s "$entry" "$out/$name"
            fi
          done

          # Keep only the UWSM entry, renamed to plain "Hyprland".
          cp ${pkgs.hyprland}/share/wayland-sessions/hyprland-uwsm.desktop \
            $out/share/wayland-sessions/hyprland-uwsm.desktop

          substituteInPlace $out/share/wayland-sessions/hyprland-uwsm.desktop \
            --replace-fail "Name=Hyprland (uwsm-managed)" "Name=Hyprland" \
            --replace-fail "hyprland.desktop" "-- ${pkgs.hyprland}/bin/start-hyprland"
        '';
    in
      base
      // {
        # The NixOS Hyprland module calls genFinalPackage, which expects an
        # override function. Return the wrapper unchanged.
        override = _: hyprlandSession;
      };
  in {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = hyprlandSession;
    };

    home-manager.users.${username}.imports = [hm.hyprland];
  };

  flake.modules.homeManager.hyprland = {pkgs, ...}: let
    sessionVariables = {
      TERMINAL = "ghostty";
      BROWSER = "zen";
      FILE_MANAGER = "thunar";
      HYPR_GAME_WORKSPACE = 6;
      HYPR_GAME_WORKSPACE_ICON = "󰊴";
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
