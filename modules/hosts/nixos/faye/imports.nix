{
  config,
  inputs,
  ...
}: {
  configurations.nixos.faye.module = {
    imports = with config.flake.modules.nixos;
      [
        base
        desktop
        hyprland
        amdgpu
        gaming
        docker
        tailscale
      ]
      ++ [
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        ../../../../hosts/nixos/faye/hardware-configuration.nix
        ../../../../hosts/nixos/faye/disko-config.nix
      ];
  };
}
