_: {
  flake.modules.homeManager.git = _: {
    programs.git = {
      enable = true;
      settings = {
        user.name = "Arturo";
        user.email = "29128253+aig77@users.noreply.github.com";
      };
    };
  };
}
