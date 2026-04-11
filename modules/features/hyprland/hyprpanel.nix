{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland-hyprpanel = _: {
    home-manager.users.${username}.imports = [
      hm.hyprland
      hm.hyprpanelShell
      hm.screenshot
      {wayland.windowManager.hyprland.settings.exec-once = ["hyprpanel"];}
    ];
  };
}
