_: {
  flake.modules.nixos.hetzner-storagebox = {config, lib, pkgs, ...}: let
    cfg = config.hetzner-storagebox;
  in {
    options.hetzner-storagebox = {
      enable = lib.mkEnableOption "Hetzner Storage Box rclone mount";
      host = lib.mkOption {type = lib.types.str; default = "uXXXXXX.your-storagebox.de";};
      user = lib.mkOption {type = lib.types.str; default = "uXXXXXX";};
      port = lib.mkOption {type = lib.types.port; default = 23;};
      remotePath = lib.mkOption {type = lib.types.str; default = "media";};
      mountpoint = lib.mkOption {type = lib.types.str; default = "/mnt/storagebox";};

      identityFile = lib.mkOption {type = lib.types.nullOr lib.types.path; default = null;};
      knownHostsFile = lib.mkOption {type = lib.types.nullOr lib.types.path; default = null;};

      uid = lib.mkOption {type = lib.types.either lib.types.int lib.types.str; default = 0;};
      gid = lib.mkOption {type = lib.types.either lib.types.int lib.types.str; default = 0;};
      umask = lib.mkOption {type = lib.types.str; default = "022";};

      cacheDir = lib.mkOption {type = lib.types.str; default = "/var/cache/rclone/storagebox";};
      cacheMaxSize = lib.mkOption {type = lib.types.str; default = "100G";};
      cacheMinFreeSpace = lib.mkOption {type = lib.types.str; default = "20G";};
      readAhead = lib.mkOption {type = lib.types.str; default = "1G";};
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.identityFile != null;
          message = "hetzner-storagebox: identityFile is required when enabled";
        }
        {
          assertion = cfg.knownHostsFile != null;
          message = "hetzner-storagebox: knownHostsFile is required when enabled";
        }
      ];

      environment.systemPackages = [pkgs.rclone pkgs.fuse3];
      system.fsPackages = [pkgs.rclone];
      environment.etc."fuse.conf".text = "user_allow_other";

      environment.etc."rclone-storagebox.conf".text = ''
        [storagebox]
        type = sftp
        host = ${cfg.host}
        user = ${cfg.user}
        port = ${toString cfg.port}
        key_file = ${cfg.identityFile}
        ${lib.optionalString (cfg.knownHostsFile != null) "known_hosts_file = ${cfg.knownHostsFile}"}
        shell_type = unix
        md5sum_command = md5sum
        sha1sum_command = sha1sum
      '';

      systemd.mounts = [{
        description = "Hetzner Storage Box (rclone)";
        what = "storagebox:${cfg.remotePath}";
        where = cfg.mountpoint;
        type = "rclone";
        options = "rw,_netdev,allow_other,args2env,"
          + "config=/etc/rclone-storagebox.conf,"
          + "cache-dir=${cfg.cacheDir},vfs-cache-mode=full,"
          + "vfs-cache-max-size=${cfg.cacheMaxSize},"
          + "vfs-cache-min-free-space=${cfg.cacheMinFreeSpace},"
          + "vfs-read-ahead=${cfg.readAhead},buffer-size=64M,"
          + "dir-cache-time=1h,sftp-chunk-size=255k,"
          + "uid=${cfg.uid},gid=${cfg.gid},umask=${cfg.umask}";
      }];
      systemd.automounts = [{where = cfg.mountpoint; wantedBy = ["multi-user.target"];}];
      systemd.tmpfiles.rules = [
        "d ${cfg.mountpoint} 0755 root root -"
        "d ${cfg.cacheDir} 0700 root root -"
      ];
    };
  };
}
