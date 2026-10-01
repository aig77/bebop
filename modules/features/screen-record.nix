{
  flake.modules.nixos.screen-record = {
    programs.gpu-screen-recorder = {
      enable = true;
      ui.enable = true;
    };
  };
}
