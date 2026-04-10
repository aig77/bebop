{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos = {
    base = {config, ...}: {
      imports = [inputs.home-manager.nixosModules.home-manager];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {
          inherit inputs;
          inherit (config) var;
        };
        users.${username}.imports = [hm.base];
      };
    };

    desktop = _: {
      home-manager.users.${username}.imports = [hm.gui hm.eyecandyNixos hm.nvimStylix];
    };

    hyprland-custom = _: {
      home-manager.users.${username}.imports = [
        hm.hyprland
        hm.customDesktopShell
        {wayland.windowManager.hyprland.settings.exec-once = ["waybar" "playerctld"];}
        hm.screenshot # hyprland-specific (grimblast/hyprshot)
      ];
    };

    hyprland-hyprpanel = _: {
      home-manager.users.${username}.imports = [
        hm.hyprland
        hm.hyprpanelShell
        {wayland.windowManager.hyprland.settings.exec-once = ["hyprpanel"];}
        hm.screenshot # hyprland-specific (grimblast/hyprshot)
      ];
    };

    hyprland-quickshell = _: {
      var.launcher = "quickshell";
      home-manager.users.${username}.imports = [
        hm.hyprland
        hm.quickshell
        {
          wayland.windowManager.hyprland.settings.exec-once = ["quickshell"];
          wayland.windowManager.hyprland.settings.bindd = ["ALT, tab, Workspace Overview, exec, qs ipc call overview toggle"];
        }
        hm.screenshot # hyprland-specific (grimblast/hyprshot)
      ];
    };

    niri = _: {
      home-manager.users.${username}.imports = [
        hm.niri
        hm.customDesktopShell
        {
          programs.niri.settings.spawn-at-startup = [
            {command = ["waybar"];}
          ];
        }
      ];
    };

    gnome = _: {
      home-manager.users.${username}.imports = [hm.gnome];
    };

    gaming = _: {
      home-manager.users.${username}.imports = [hm.gaming];
    };

    amdgpu = _: {
      home-manager.users.${username}.imports = [hm.btopAmd];
    };

    nvidia = _: {
      home-manager.users.${username}.imports = [hm.btopNvidia];
    };
  };
}
