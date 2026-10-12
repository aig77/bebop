{config, ...}: {
  configurations.nixos.ed.module = {
    imports = with config.flake.modules.nixos; [
      base
      server
      observability-agent
      dns
      tailscale-router
    ];
    nixpkgs.hostPlatform = "aarch64-linux";
    nix.settings.filter-syscalls = false;
  };
}
