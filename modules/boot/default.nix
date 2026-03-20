_: {
  flake.modules.nixos.desktop = {
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.grub2-themes.nixosModules.default];

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      loader = {
        grub = {
          enable = true;
          efiSupport = true;
          useOSProber = true;
          devices = ["nodev"];
        };
        grub2-theme = {
          enable = true;
          theme = "vimix";
          screen = "2k";
        };
        efi.canTouchEfiVariables = true;
        timeout = 3;
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
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "systemd.show_status=auto"
      ];

      binfmt.emulatedSystems = ["aarch64-linux"];
    };

    stylix.targets.grub.enable = false;
    stylix.targets.plymouth.enable = false;
  };
}
