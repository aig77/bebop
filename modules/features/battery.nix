{
  flake.modules.nixos.battery = {
    services = {
      power-profiles-daemon.enable = true;
      upower.enable = true;
    };
  };
}
