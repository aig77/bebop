_: {
  flake.modules.homeManager.base = {var, ...}: {
    programs.git = {
      enable = true;
      settings = {
        user.name = var.username;
      };
    };
  };
}
