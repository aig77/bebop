_: {
  flake.modules.homeManager.eyecandyPackages = {pkgs, ...}: {
    home.packages = with pkgs; [
      krabby
      cmatrix
      pipes-rs
      cbonsai
      asciiquarium
      lavat
      lolcat
      sl
      nms
    ];
  };
}
