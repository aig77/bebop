{config, ...}: {
  flake.modules.homeManager.customDesktopShell = {
    imports = let
      hm = config.flake.modules.homeManager;
    in [
      hm.waybarSimple
      hm.swaync
      hm.fuzzel
      hm.hyprlock
      hm.hypridle
    ];
  };
}
