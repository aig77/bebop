_: {
  flake.modules.homeManager.shell = {var, ...}: {
    programs.git = {
      enable = true;
      settings = {
        user.name = var.username;
      };
    };
  };
}
