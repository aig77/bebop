_: {
  flake.modules.homeManager.gui = _: {
    programs.discord = {
      enable = true;
      settings = {
        SKIP_HOST_UPDATE = true;
        MINIMIZE_TO_TRAY = false;
      };
    };
  };
}
