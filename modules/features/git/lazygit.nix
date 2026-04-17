_: {
  flake.modules.homeManager.shell = _: {
    programs.lazygit = {
      enable = true;
    };
  };
}
