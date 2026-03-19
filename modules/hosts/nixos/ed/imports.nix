{config, ...}: {
  configurations.nixos.ed.module = {
    imports = with config.flake.modules.nixos; [
      base
      tailscale
      server
    ];
    nixpkgs.hostPlatform = "aarch64-linux";
  };
}
