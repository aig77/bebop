{config, ...}: {
  configurations.nixos.faye.module = {inputs, ...}: {
    remote-builder.host = "jet";
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        amdgpu
        htpc
        steamos
        no-rgb
        remote-builder
      ]);
  };
}
