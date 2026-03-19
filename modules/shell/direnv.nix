_: {
  flake.modules.homeManager.base = _: {
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
    };
  };
}
