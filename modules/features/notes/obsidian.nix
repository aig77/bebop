_: {
  flake.modules.homeManager.gui = _: {
    programs.obsidian.enable = true;
    stylix.targets.obsidian.enable = false;
  };
}
