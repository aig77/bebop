{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.darwin.eyecandy = _: {
    home-manager.users.${username}.imports = [hm.eyecandyBase];
  };
}
