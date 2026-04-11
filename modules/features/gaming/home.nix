_: {
  flake.modules.homeManager.gaming = {pkgs, ...}: {
    home.packages = with pkgs; [
      mangohud
      heroic
      bottles
      protonplus
    ];
  };
}
