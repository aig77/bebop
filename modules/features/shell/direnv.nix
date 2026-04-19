_: {
  flake.modules.homeManager.shell = _: {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
