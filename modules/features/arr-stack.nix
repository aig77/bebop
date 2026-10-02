{
  config,
  inputs,
  ...
}: let
  inherit (config.flake) nixos;
  stateDir = "/var/lib/nixarr";
in {
  flake.modules.nixos.arr-stack = {
    imports = [
      inputs.nixarr.nixosModules.default
      nixos.protonvpn
    ];

    var.services = {
      sonarr = {
        subdomain = "sonarr";
        port = config.ports.arr.sonarr;
        public = false;
        monitor = {
          enable = true;
          path = "/api/v3/health";
        };
      };
      radarr = {
        subdomain = "radarr";
        port = config.ports.arr.radarr;
        public = false;
        monitor = {
          enable = true;
          path = "/api/v3/health";
        };
      };
      prowlarr = {
        subdomain = "prowlarr";
        port = config.ports.arr.prowlarr;
        public = false;
        monitor = {
          enable = true;
          path = "/api/v1/health";
        };
        backup.paths = [stateDir]; # just add to one of them, not related to this service
      };
      bazarr = {
        subdomain = "bazarr";
        port = config.ports.arr.bazarr;
        public = false;
        monitor = {
          enable = true;
          path = "/api/health";
        };
      };
      sabnzbd = {
        subdomain = "sabnzbd";
        port = config.ports.arr.sabnzbd;
        public = false;
        monitor = {
          enable = true;
          type = "tcp";
        };
      };
      # monitored and linked: you touch these directly
      jellyfin = {
        subdomain = "jellyfin";
        port = config.ports.arr.jellyfin;
        public = true;
        auth = false;
        monitor = {
          enable = true;
          path = "/health";
        };
        homepage = {
          enable = true;
          icon = "si:jellyfin";
        };
      };
      jellyseerr = {
        subdomain = "seerr";
        port = config.ports.arr.jellyseerr;
        public = false;
        monitor = {
          enable = true;
          type = "tcp";
        };
        homepage = {
          enable = true;
          icon = "di:jellyseerr";
        };
      };

      transmission = {
        subdomain = "transmission";
        port = config.ports.arr.qbittorrent;
        public = false;
        monitor = {
          enable = true;
          type = "tcp";
          interval = "1m";
        };
        homepage = {
          enable = true;
          icon = "si:transmission";
        };
      };
    };

    nixarr = {
      enable = true;
      mediaDir = "/data/media";
      inherit stateDir;

      vpn = {
        enable = true;
        wgConf = config.sops.templates."protonvpn-wg-conf".path; # imported from nixos.protonvpn
        proxyListenAddr = "127.0.0.1";
        exposeOnLAN = false;
        vpnTestService.enable = true;
        openUdpPorts = [config.ports.arr.qbittorrentPeer];
      };

      transmission = {
        enable = true;
        vpn.enable = true;
        peerPort = config.ports.arr.qbittorrentPeer;
        uiPort = config.ports.arr.qbittorrent;
      };

      jellyfin = {
        enable = true;
        port = config.ports.arr.jellyfin;
      };

      seerr = {
        enable = true;
        port = config.ports.arr.jellyseerr;
      };

      sonarr = {
        enable = true;
        port = config.ports.arr.sonarr;
        settings-sync.transmission.enable = true;
      };

      radarr = {
        enable = true;
        port = config.ports.arr.radarr;
        settings-sync.transmission.enable = true;
      };

      prowlarr = {
        enable = true;
        port = config.ports.arr.prowlarr;
        settings-sync = {
          # Automatically sync all enabled Nixarr apps to Prowlarr.
          # This adds Sonarr, Radarr, Lidarr, and Readarr as applications
          # with the correct URLs and API keys — no manual setup needed.
          enable-nixarr-apps = true;
        };
      };

      bazarr = {
        enable = true;
        port = config.ports.arr.bazarr;
        settings-sync = {
          # Automatically configure the Sonarr connection in Bazarr.
          # API keys and ports are filled in from Nixarr's configuration.
          sonarr.enable = true;
          sonarr.config = {
            # Optionally only sync subtitles for monitored content
            sync_only_monitored_series = true;
            sync_only_monitored_episodes = true;
          };
          # Same for Radarr
          radarr.enable = true;
          radarr.config.sync_only_monitored_movies = true;
        };
      };

      sabnzbd = {
        enable = true;
        guiPort = config.ports.arr.sabnzbd;
      };
    };
  };
}
