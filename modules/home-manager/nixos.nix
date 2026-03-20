{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos = {
    base = {config, ...}: {
      imports = [inputs.home-manager.nixosModules.home-manager];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          inherit inputs;
          inherit (config) var;
        };
        users.${username}.imports = [hm.base];
      };
    };
    desktop = _: {
      home-manager.users.${username}.imports = [hm.gui];
    };
    hyprland = _: {
      home-manager.users.${username}.imports = [
        hm.hyprland
        hm.fuzzel
        hm.hyprlock
        hm.hypridle
        hm.screenshot
      ];
    };
    niri = _: {
      home-manager.users.${username}.imports = [
        hm.niri
        hm.waybar
        hm.mako
        hm.fuzzel
        hm.hyprlock
        hm.hypridle
      ];
    };
    gnome = _: {
      home-manager.users.${username}.imports = [hm.gnome];
    };
    gaming = _: {
      home-manager.users.${username}.imports = [hm.gaming];
    };
  };
}
