{config, ...}: {
  flake.modules.homeManager.hyprpanelShell = {
    imports = let
      hm = config.flake.modules.homeManager;
    in [
      hm.hyprpanel
      hm.hyprlock
      hm.hypridle
      hm.fuzzel
    ];
  };
}
