_: {
  flake.modules.homeManager.gui = _: {
    programs.vesktop = {
      enable = false;
      settings = {
        minimizeToTray = false;
        hardwareAcceleration = true;
        hardwareVideoAcceleration = true;
      };
    };
  };
}
