_: {
  flake.modules.homeManager.base = _: {
    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
      };
    };
  };
}
