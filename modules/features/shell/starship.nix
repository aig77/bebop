_: {
  flake.modules.homeManager.shell = _: {
    programs.starship = {
      enable = true;
      settings = {
        add_newline = true;
      };
    };
  };
}
