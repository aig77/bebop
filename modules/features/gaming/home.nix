_: {
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
}
