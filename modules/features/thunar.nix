_: {
  flake.modules.nixos.thunar = {pkgs, ...}: let
    thunarArchivePlugin = pkgs.thunar-archive-plugin.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          ln -s ${pkgs.xarchiver}/libexec/thunar-archive-plugin/xarchiver.tap \
            $out/libexec/thunar-archive-plugin/xarchiver.tap
        '';
    });
  in {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunarArchivePlugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };

    services = {
      udisks2.enable = true;
      gvfs.enable = true;
      tumbler.enable = true;
    };

    environment.systemPackages = [pkgs.xarchiver];

    programs.xfconf.enable = true;
    xdg.mime.defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "application/zip" = "xarchiver.desktop";
      "application/x-7z-compressed" = "xarchiver.desktop";
      "application/x-tar" = "xarchiver.desktop";
      "application/x-compressed-tar" = "xarchiver.desktop"; # .tar.gz, .tgz
      "application/x-bzip-compressed-tar" = "xarchiver.desktop"; # .tar.bz2
      "application/x-bzip2-compressed-tar" = "xarchiver.desktop";
      "application/x-xz-compressed-tar" = "xarchiver.desktop"; # .tar.xz
      "application/x-zstd-compressed-tar" = "xarchiver.desktop"; # .tar.zst
      "application/vnd.rar" = "xarchiver.desktop";
      "application/x-rar" = "xarchiver.desktop";
    };
  };
}
