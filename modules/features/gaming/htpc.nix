{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.htpc = {inputs, ...}: {
    imports = [inputs.jovian-nixos.nixosModules.default];

    services.desktopManager.plasma6.enable = true;

    jovian = {
      steam = {
        enable = true;
        autoStart = true;
        user = username;
        desktopSession = "plasma";
      };
      decky-loader = {
        enable = true;
        user = username;
      };
      steamos.useSteamOSConfig = true;
      hardware.has.amd.gpu = true;
    };

    # Allows power on from sleep with controller
    hardware.xone.enable = true;
    users.users.${username}.extraGroups = ["input"]; # Required for previous option

    home-manager.users.${username}.imports = [hm.gaming];
  };
}
