_: {
  flake.modules.nixos.xserver = {
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
}
