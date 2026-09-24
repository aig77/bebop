{config, ...}: {
  configurations.nixos.ein.module = {inputs, ...}: {
    remote-builder.host = "jet";
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        laptop
        hyprland
        niri
        intelgpu
        fingerprint-scan
        gaming
        docker
        remote-builder
      ]);
  };
}
