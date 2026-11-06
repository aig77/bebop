{config, ...}: let
  inherit (config.flake.meta.owner) username;
  inherit (config.flake.modules) nixos;
  hm = config.flake.modules.homeManager;
in {
  flake.modules = {
    nixos = {
      gaming = {pkgs, ...}: {
        imports = [nixos.screen-record];
        programs = {
          steam = {
            enable = true;
            remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
            dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server hosting
            gamescopeSession.enable = true;
            extraCompatPackages = with pkgs; [
              proton-ge-bin
            ];
          };
          gamemode.enable = true;
        };

        hardware.xone.enable = true;

        environment.sessionVariables = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\\\${HOME}/.steam/root/compatibilitytools.d";
        };

        home-manager.users.${username}.imports = [hm.gaming];
      };

      gaming-mods = {
        inputs,
        pkgs,
        ...
      }: {
        environment.systemPackages = [inputs.amethyst.packages.${pkgs.system}.default];
        home-manager.users.${username}.imports = [hm.gaming-mods];
      };
    };

    homeManager.gaming = {pkgs, ...}: {
      home.packages = with pkgs; [
        heroic
        bottles
        protonplus
      ];

      programs.mangohud = {
        enable = true;
        settings = {
          pci_dev = "0:03:00.0";

          gpu_stats = true;
          gpu_temp = true;
          gpu_core_clock = true;
          gpu_mem_clock = true;
          gpu_vram_used = true;
          gpu_power = true;

          cpu_stats = true;
          cpu_temp = true;
          cpu_mhz = true;

          fps = true;
          frametime = true;
          frame_timing = 1;

          ram = true;
          vram = true;

          wine = true;
          toggle_hud = "Shift_R+F2";
          position = "top-left";
        };
      };
    };

    homeManager.gaming-mods = {pkgs, ...}: {
      home = {
        packages = [
          pkgs.protontricks
          (pkgs.writeShellScriptBin "me3" ''
            unset LD_LIBRARY_PATH LD_PRELOAD LD_AUDIT
            exec ${pkgs.steam-run}/bin/steam-run "$HOME/.local/bin/me3" "$@"
          '')
        ];
        sessionVariables = {
          AMM_STEAM_OVERLAY = "0";
        };
      };
    };

    nixos.steamos = {inputs, ...}: {
      imports = [inputs.jovian-nixos.nixosModules.default];

      services.desktopManager.plasma6.enable = true;

      jovian = {
        steam = {
          enable = true;
          autoStart = true;
          user = username;
          desktopSession = "plasma";
        };
        decky-loader = {
          enable = true;
          user = username;
        };
        steamos.useSteamOSConfig = true;
        hardware.has.amd.gpu = true;
      };

      # Steam/gamescope don't always shut down cleanly -- cap wait time
      systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

      # Allows power on from sleep with controller
      hardware.xone.enable = true;
      users.users.${username}.extraGroups = ["input"]; # Required for previous option

      # Required for Decky Loader to appear in the Steam overlay
      systemd.services.steam-cef-debug = {
        description = "Create Steam CEF debugging file for Decky Loader";
        serviceConfig = {
          Type = "oneshot";
          User = username;
          ExecStart = "/bin/sh -c 'mkdir -p ~/.steam/steam && [ ! -f ~/.steam/steam/.cef-enable-remote-debugging ] && touch ~/.steam/steam/.cef-enable-remote-debugging || true'";
        };
        wantedBy = ["multi-user.target"];
      };

      home-manager.users.${username}.imports = [hm.gaming];
    };
  };
}
