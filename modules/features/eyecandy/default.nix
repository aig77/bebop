{config, ...}: let
  ec = config.flake.modules.generic;
in {
  flake.modules.homeManager = {
    eyecandyBase = {
      imports = [ec.eyecandyFastfetch ec.eyecandyFetchAlias ec.eyecandyPackages];
    };

    eyecandyNixos = {pkgs, ...}: {
      imports = [ec.eyecandyFastfetch ec.eyecandyFetchAlias ec.eyecandyPackages ec.eyecandyCava];
      home.packages = [pkgs.tty-clock];
    };
  };
}
