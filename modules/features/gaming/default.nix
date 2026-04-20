{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.homeManager.gaming = {pkgs, ...}: {
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
        toggle_hud = "F12";
        position = "top-left";
      };
    };
  };

  flake.modules.nixos.gaming = _: {
    programs = {
      steam.enable = true;
      steam.gamescopeSession = {
        enable = true;
        args = [
          "-f"
          "-w 2560"
          "-h 1440"
          "--cursor-lock-enabled"
        ];
      };
      gamemode.enable = true;
    };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\\\${HOME}/.steam/root/compatibilitytools.d";
    };

    home-manager.users.${username}.imports = [hm.gaming];
  };
}
