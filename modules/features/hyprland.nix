{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland = {
    inputs,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;
  in {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    home-manager.users.${username}.imports = [hm.hyprland];
  };

  flake.modules.homeManager.hyprland = {
    pkgs,
    var,
    ...
  }: let
    sessionVariables = {
      TERMINAL = var.terminal;
      BROWSER = var.browser;
      FILE_MANAGER = var.fileManager;
      LOCATION = var.location;
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
