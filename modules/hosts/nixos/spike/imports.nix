{config, ...}: {
  configurations.nixos.spike.module = {inputs, ...}: {
    remote-builder.host = "jet";
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        aarch64-builder
        remote-builder
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
