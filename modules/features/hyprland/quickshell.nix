{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.hyprland-quickshell = _: {
    var.launcher = "quickshell";
    home-manager.users.${username}.imports = [
      hm.hyprland
      hm.quickshell
      hm.screenshot
      {
        wayland.windowManager.hyprland.settings.exec-once = ["quickshell"];
        wayland.windowManager.hyprland.settings.bindd = [
          "ALT, tab, Workspace Overview, exec, qs ipc call overview toggle"
        ];
      }
    ];
  };
}
