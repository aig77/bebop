_: {
  flake.modules.homeManager.base = _: {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 24;
            y = 16;
          };
        };
      };
    };
  };
}
