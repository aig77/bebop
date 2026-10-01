{config, ...}: let
  inherit (config.flake.meta.owner) username;
  inherit (config.flake.modules) nixos;
  hm = config.flake.modules.homeManager;
in {
  flake.modules = {
    nixos.gui = {
      inputs,
      pkgs,
      ...
    }: let
      claude-desktop = inputs.claude-desktop.packages.${pkgs.system}.claude-desktop-fhs;
    in {
      imports = with nixos; [xserver keyring printing polkit];
      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        bitwarden-cli
        claude-desktop
        easyeffects
        gnome-calculator
        gram
        imv
        mission-center
        pavucontrol
        qpwgraph
        vlc
      ];
      home-manager.users.${username}.imports = [hm.gui];
    };

    homeManager.gui = {var, ...}: {
      imports =
        [hm.${var.terminal}]
        ++ (with hm; [
          eyecandy-nixos
          shell

          discord
          nixcord
          obsidian
          spotify
          zathura
          zen
        ]);
    };
  };
}
