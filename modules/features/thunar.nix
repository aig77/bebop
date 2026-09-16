_: {
  flake.modules.nixos.thunar = {pkgs, ...}: {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [thunar-archive-plugin thunar-media-tags-plugin thunar-volman];
    };
    services = {
      udisks2.enable = true;
      gvfs.enable = true;
      tumbler.enable = true;
    };
    environment.systemPackages = [pkgs.xarchiver];

    programs.xfconf.enable = true;
    xdg.mime.defaultApplications."inode/directory" = "thunar.desktop";
  };
}
