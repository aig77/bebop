_: {
  flake.modules.homeManager.base = _: {
    programs.zoxide = {
      enable = true;
      options = ["--cmd cd"];
    };
  };
}
