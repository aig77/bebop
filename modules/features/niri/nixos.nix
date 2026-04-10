{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.niri = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.niri.nixosModules.niri];

    nixpkgs.overlays = [inputs.niri.overlays.niri];

    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };

    services.displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      sessionPackages = [
        config.home-manager.users.${config.var.username}.programs.niri.package
      ];
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gnome];
      config.common.default = "gtk";
    };

    home-manager.users.${username}.imports = [
      hm.niri
      hm.customDesktopShell
      {programs.niri.settings.spawn-at-startup = [{command = ["waybar"];}];}
    ];
  };
}
