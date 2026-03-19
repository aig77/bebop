_: {
  configurations.nixos.ed.module = {
    config,
    pkgs,
    ...
  }: {
    networking.hostName = config.var.hostname;

    boot = {
      kernelPackages = pkgs.linuxPackages;
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
      growPartition = true;
      tmp.useTmpfs = true;
      kernelParams = [
        "panic=10"
        "boot.shell_on_fail"
      ];
    };

    systemd.settings.Manager = {
      RebootWatchdogSec = "10min";
      RuntimeWatchdogSec = "60s";
    };
    boot.kernelModules = ["bcm2835_wdt"];

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = ["noatime"];
      };
    };

    services = {
      getty.autologinUser = config.var.username;
      openssh.enable = true;
    };

    hardware.enableRedistributableFirmware = true;

    environment.systemPackages = with pkgs; [
      htop
    ];
  };
}
