{config, ...}: {
  configurations.nixos.spike.module = {inputs, ...}: {
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        aarch64-builder
        jet-builder
        desktop
        hyprland
        niri
        amdgpu
        gaming
        docker
        volt
      ]);
  };
}
