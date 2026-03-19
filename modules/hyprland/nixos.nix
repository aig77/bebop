_: {
  flake.modules.nixos.hyprland = {
    inputs,
    pkgs,
    ...
  }: {
    services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}
