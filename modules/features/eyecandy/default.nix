{config, ...}: let
  hm = config.flake.modules.homeManager;
in {
  flake.modules.homeManager = {
    eyecandyBase = {
      imports = [hm.fastfetch hm.krabby hm.eyecandyPackages];
    };

    eyecandyNixos = {pkgs, ...}: {
      imports = [hm.fastfetch hm.krabby hm.eyecandyPackages hm.cava];
      home.packages = [pkgs.tty-clock];
    };
  };
}
