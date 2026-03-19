_: {
  flake.modules.homeManager.base = _: {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          padding = {
            x = 10;
            y = 10;
          };
        };
      };
    };
  };
}
