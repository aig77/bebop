_: {
  flake.modules.nixos.base = {config, ...}: {
    networking = {
      hostName = config.var.hostname;
      networkmanager.enable = true;
    };
    time.timeZone = "America/New_York";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    services = {
      xserver = {
        enable = true;
        xkb.layout = "us";
        xkb.variant = "";
      };
      gnome.gnome-keyring.enable = true;
      openssh.enable = true;
      printing.enable = true;
      udisks2.enable = true;
      gvfs.enable = true;
      tumbler.enable = true;
    };
    security.polkit.enable = true;
  };
}
