{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos;
  stateDir = "/var/lib/nixarr";
in {
  flake.modules.nixos.arr = {config, ...}: let
    downloadClients = [
      {
        name = "SABnzbd";
        implementation = "Sabnzbd";
        fields = {
          host = "localhost";
          port = config.ports.arr.sabnzbd;
          apiKey.secret = config.sops.secrets."arr/sabnzbd-api-key".path;
        };
      }
    ];
  in {
    imports = [
      inputs.nixarr.nixosModules.default
      nixos.protonvpn
    ];

    users = {
      groups.arr-secrets = {};
      users = {
        sonarr.extraGroups = ["arr-secrets"];
        radarr.extraGroups = ["arr-secrets"];
      };
    };

    sops.secrets."arr/sabnzbd-api-key" = {
      mode = "0440";
      group = "arr-secrets";
      restartUnits = [
        "sonarr-sync-config.service"
        "radarr-sync-config.service"
      ];
    };

    var.services = {
      # public
      jellyfin = {
        subdomain = "jellyfin";
        port = config.ports.arr.jellyfin;
        public = true;
        monitor = {
          enable = true;
          path = "/health";
        };
        homepage = {
          enable = true;
          icon = "si:jellyfin";
        };
        backup.paths = [stateDir]; # just add to one of them, not related to this service
      };

      # private
      jellyseerr = {
        subdomain = "jellyseerr";
        port = config.ports.arr.jellyseerr;
        monitor = {
          enable = true;
          type = "tcp";
        };
        homepage = {
          enable = true;
          icon = "di:jellyseerr";
        };
      };
      sonarr = {
        subdomain = "sonarr";
        port = config.ports.arr.sonarr;
        monitor = {
          enable = true;
          path = "/api/v3/health";
        };
        homepage = {
          enable = true;
          icon = "si:sonarr";
        };
      };
      radarr = {
        subdomain = "radarr";
        port = config.ports.arr.radarr;
        monitor = {
          enable = true;
          path = "/api/v3/health";
        };
        homepage = {
          enable = true;
          icon = "si:radarr";
        };
      };
      prowlarr = {
        subdomain = "prowlarr";
        port = config.ports.arr.prowlarr;
        monitor = {
          enable = true;
          path = "/api/v1/health";
        };
        homepage = {
          enable = true;
          icon = "si:prowlarr";
        };
      };
      bazarr = {
        subdomain = "bazarr";
        port = config.ports.arr.bazarr;
        monitor = {
          enable = true;
          path = "/api/health";
        };
        homepage = {
          enable = true;
          icon = "si:bazarr";
        };
      };
      transmission = {
        subdomain = "transmission";
        port = config.ports.arr.transmission;
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
      sabnzbd = {
        subdomain = "sabnzbd";
        port = config.ports.arr.sabnzbd;
        monitor = {
          enable = true;
          type = "tcp";
          interval = "1m";
        };
        homepage = {
          enable = true;
          icon = "si:sabnzbd";
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
        openUdpPorts = [config.ports.arr.transmissionPeer];
      };

      # Torrent Downloads
      transmission = {
        enable = true;
        vpn.enable = true;
        peerPort = config.ports.arr.transmissionPeer;
        uiPort = config.ports.arr.transmission;
      };

      # Usenet Downloads
      sabnzbd = {
        enable = true;
        guiPort = config.ports.arr.sabnzbd;
      };

      # Streaming
      jellyfin = {
        enable = true;
        port = config.ports.arr.jellyfin;
      };

      # Media Requesting
      seerr = {
        enable = true;
        port = config.ports.arr.jellyseerr;
      };

      # TV Show Automation
      sonarr = {
        enable = true;
        port = config.ports.arr.sonarr;
        settings-sync = {
          transmission.enable = true;
          inherit downloadClients;
        };
      };

      # Movie Automation
      radarr = {
        enable = true;
        port = config.ports.arr.radarr;
        settings-sync = {
          transmission.enable = true;
          inherit downloadClients;
        };
      };

      # Index Manager
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

      # Subtitle Automation
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
    };

    # Required for settings-sync to work
    services = {
      prowlarr.settings.auth.required = "DisabledForLocalAddresses";
      sonarr.settings.auth.required = "DisabledForLocalAddresses";
      radarr.settings.auth.required = "DisabledForLocalAddresses";
    };
  };
}
