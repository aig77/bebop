{config, ...}: {
  flake.modules.homeManager.quickshell = {
    imports = let
      hm = config.flake.modules.homeManager;
    in [
      hm.quickshellHm
      hm.swaync
      hm.fuzzel
      hm.hyprlock
      hm.hypridle
      hm.wallpaperManager
    ];
  };
}
