_: {
  flake.modules.homeManager.waypaper = {
    pkgs,
    var,
    ...
  }: let
    wallpaper-picker = pkgs.writeShellScriptBin "wallpaper-picker" ''
      exec ${pkgs.waypaper}/bin/waypaper
    '';
  in {
    home.packages = [pkgs.waypaper wallpaper-picker];

    xdg.configFile."waypaper/config.ini".text = ''
      [Settings]
      folder = ~/Pictures/Wallpapers
      wallpaper = ~/Pictures/Wallpapers
      backend = ${var.wallpaperEngine}
      monitors = All
      fill = fill
      sort = name
      subfolders = False
      number_of_columns = 4
      post_command = ln -sf $wallpaper ~/.cache/bebop/current-wallpaper
    '';
  };
}
