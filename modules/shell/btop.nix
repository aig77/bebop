_: {
  flake.modules.homeManager.base = {lib, config, ...}:
    lib.mkMerge [
      {
        programs.btop.enable = true;
      }
      (lib.mkIf (config.lib ? stylix) {
        stylix.targets.btop.enable = true;
      })
    ];
}
