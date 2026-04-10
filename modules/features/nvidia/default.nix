{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.nvidia = _: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = ["nvidia"];

    boot.kernelParams = ["nvidia-drm.modeset=1"];

    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      GBM_BACKEND = "nvidia-drm";
    };

    nixpkgs.config = {
      nvidia.acceptLicense = true;
      allowUnfree = true;
    };

    hardware.nvidia = {
      open = false;
      nvidiaSettings = false;
      modesetting.enable = true;
      powerManagement.enable = true;
    };

    home-manager.users.${username}.imports = [hm.btopNvidia];
  };
}
