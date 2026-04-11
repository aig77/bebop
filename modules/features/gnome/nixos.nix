{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.gnome = {pkgs, ...}: {
    services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    services.desktopManager.gnome.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      atomix
      cheese
      epiphany
      evince
      geary
      gedit
      gnome-characters
      gnome-music
      gnome-photos
      gnome-terminal
      gnome-tour
      gnome-contacts
      gnome-weather
      gnome-clocks
      gnome-maps
      gnome-console
      gnome-text-editor
      gnome-calendar
      gnome-system-monitor
      gnome-logs
      gnome-font-viewer
      gnome-sound-recorder
      gnome-disk-utility
      gnome-connections
      hitori
      iagno
      tali
      totem
      file-roller
      simple-scan
      seahorse
      decibels
      loupe
      baobab
      snapshot
    ];

    home-manager.users.${username}.imports = [hm.gnome];
  };
}
