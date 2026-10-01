{config, ...}: let
  inherit (config.flake.modules) nixos;
  hm = config.flake.modules.homeManager;
in {
  flake.modules = {
    nixos.gui = {
      imports = with nixos; [xserver keyring printing polkit];
    };

    homeManager.gui = {
      var,
      inputs,
      pkgs,
      ...
    }: let
      claude-desktop = inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-fhs;
    in {
      imports =
        [hm.${var.terminal}]
        ++ (with hm; [
          eyecandy-nixos
          shell

          bitwarden
          discord
          nixcord
          obsidian
          spotify
          zathura
          zen
        ]);
      home.packages = with pkgs; [
        claude-desktop
        gnome-calculator
        gram
        imv
        mission-center
        pavucontrol
        qpwgraph
        vlc
      ];
    };
  };
}
