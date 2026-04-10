{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland-custom = _: {
    home-manager.users.${username}.imports = [
      hm.hyprland
      hm.customDesktopShell
      hm.screenshot
      {wayland.windowManager.hyprland.settings.exec-once = ["waybar" "playerctld"];}
    ];
  };
}
