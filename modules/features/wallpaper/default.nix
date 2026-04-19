{config, ...}: {
  flake.modules.homeManager.wallpaperManager = {
    lib,
    var,
    ...
  }: let
    hm = config.flake.modules.homeManager;
  in {
    imports =
      [hm.waypaper]
      ++ lib.optionals (var.wallpaperEngine == "awww") [hm.awww];
  };
}
