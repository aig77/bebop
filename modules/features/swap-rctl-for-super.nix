# typically for laptops so that super is accessible
# with both hands
{
  flake.modules.nixos.swap-rctl-for-super = {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = ["*"];
        settings.main = {
          rightcontrol = "rightmeta";
        };
      };
    };
  };
}
