_: {
  flake.modules.homeManager.shell = _: {
    programs.zoxide = {
      enable = true;
      options = ["--cmd cd"];
    };
  };
}
