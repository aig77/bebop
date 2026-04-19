_: let
  hyprlandNixos = {
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
in {
  flake.modules.nixos = {
    hyprland = hyprlandNixos;
    hyprland-custom = hyprlandNixos;
    hyprland-hyprpanel = hyprlandNixos;
    hyprland-quickshell = hyprlandNixos;
  };
}
