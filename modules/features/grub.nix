_: {
  flake.modules.nixos.grub = {
    pkgs,
    inputs,
    ...
  }: {
    imports = [inputs.grub2-themes.nixosModules.default];

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      loader = {
        timeout = 3;
        grub = {
          enable = true;
          efiSupport = true;
          useOSProber = true;
          devices = ["nodev"];
          extraConfig = ''
            terminal_input console
            terminal_output console
            set timeout_style=hidden
          '';
        };
        grub2-theme.enable = false;
        efi.canTouchEfiVariables = true;
      };

      plymouth = {
        enable = true;
        theme = "lone";
        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = ["lone"];
          })
        ];
      };

      consoleLogLevel = 3;
      # initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "udev.log_level=3"
        "systemd.show_status=auto"
      ];
    };

    stylix.targets.grub.enable = false;
    stylix.targets.plymouth.enable = false;
  };

  flake.modules.nixos.grub-server = {pkgs, ...}: {
    boot = {
      kernelPackages = pkgs.linuxPackages; # LTS
      loader = {
        efi.canTouchEfiVariables = true;
        timeout = 1;
        grub = {
          enable = true;
          efiSupport = true;
          devices = ["nodev"];
        };
      };
    };
  };
}
