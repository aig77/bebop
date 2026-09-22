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
        ly
        thunar
      ];

      services = {
        xserver = {
          enable = true;
          xkb.layout = "us";
          xkb.variant = "";
        };
        gnome.gnome-keyring.enable = true;
        printing.enable = true;
      };
      security.polkit.enable = true;

      home-manager.users.${username} = {
        imports = with hm; [gui easyeffects noctalia];
        home.packages = [];
      };
    };

    laptop = _: {
      imports = with nixos; [
        desktop
        protonvpn
      ];
      services = {
        power-profiles-daemon.enable = true;
        upower.enable = true;
        keyd = {
          enable = true;
          keyboards.default = {
            ids = ["*"];
            settings.main = {
              rightcontrol = "rightmeta";
            };
          };
        };
      };
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
        bitwarden
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
