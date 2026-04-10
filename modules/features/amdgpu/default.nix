{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.amdgpu = _: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    home-manager.users.${username}.imports = [hm.btopAmd];
  };
}
