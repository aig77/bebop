{config, ...}: {
  configurations.nixos.faye.module = {
    imports = with config.flake.modules.nixos; [
      base
      desktop
      hyprland-quickshell
      amdgpu
      gaming
      docker
      tailscale
      volt # pins Volt 476 to stereo profile on connect
      kraken
    ];
  };
}
