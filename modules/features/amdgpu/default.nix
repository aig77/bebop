_: {
  flake.modules.nixos.amdgpu = _: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
