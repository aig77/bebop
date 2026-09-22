{config, ...}: {
  configurations.nixos.ed.module = {
    imports = with config.flake.modules.nixos; [
      base
      server
      alloy
      prometheus-client
      dns
      tailscale-router
    ];
    nixpkgs.hostPlatform = "aarch64-linux";
    nix.settings.filter-syscalls = false;
  };
}
