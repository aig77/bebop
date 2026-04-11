{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.desktop = _: {
    home-manager.users.${username}.imports = [hm.gui hm.eyecandyNixos hm.nvimStylix];
  };
}
