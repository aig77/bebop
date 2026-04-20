{config, ...}: {
  configurations.nixos.julia.module = {
    imports = with config.flake.modules.nixos; [
      base
      desktop
      amdgpu
      htpc
    ];
  };
}
