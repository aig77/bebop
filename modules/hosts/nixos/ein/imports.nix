{config, ...}: {
  configurations.nixos.ein.module = {inputs, ...}: {
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        laptop
        hyprland
        niri
        intelgpu
        gaming
        docker
        jet-builder
      ]);
  };
}
