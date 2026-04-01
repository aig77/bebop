{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.darwin = {
    base = {config, ...}: {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          inherit inputs;
          inherit (config) var;
        };
        users.${username}.imports = [hm.base hm.gui hm.nvimStylix];
      };
    };

    eyecandy = _: {
      home-manager.users.${username}.imports = [hm.eyecandyBase];
    };
  };
}
