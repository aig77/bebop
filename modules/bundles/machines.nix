{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos = {
    desktop = _: {
      imports = with nixos; [
        base
        audio
        bluetooth
        stylix-catppuccin
        grub
        gui
        nix-ld
        noctalia
        thunar
      ];
    };

    laptop = _: {
      imports = with nixos; [
        desktop
        battery
        protonvpn
        swap-rctl-for-super
      ];
    };

    htpc = _: {
      imports = with nixos; [
        base
        audio
        bluetooth
        stylix-catppuccin
        grub
      ];
      home-manager.users.${username}.imports = with hm; [
        discord
        shell-lite
        zen
      ];
      # USB keyboard+touchpad combo support (e.g. Rii mini); libinput explicit for Jovian Wayland
      boot.kernelModules = ["hid_generic"];
      services.libinput.enable = true;
    };

    server = {lib, ...}: {
      imports = with nixos; [healthchecks vulnix];
      services.getty.autologinUser = username;
      home-manager.users.${username}.imports = [hm.shell-lite];
      sops.age.keyFile = lib.mkForce "/etc/sops/age/keys.txt";
    };
  };
}
