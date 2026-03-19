{config, ...}: {
  flake.modules.homeManager.base = _: {
    home = {
      inherit (config.flake.meta.owner) username;
    };
    programs.home-manager.enable = true;
  };
}
