{config, ...}: let
  inherit (config.flake.meta.owner) username;
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.noctalia = {
    inputs,
    pkgs,
    ...
  }: {
    imports = [
      inputs.noctalia.nixosModules.default
      nixos.catppuccin-cursors
    ];

    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    services = {
      displayManager.noctalia-greeter = {
        enable = true;
        cursorTheme = {
          package = pkgs.catppuccin-cursors;
          name = "catppuccin-mocha-dark-cursors";
        };
        settings = {
          appearance = {
            scheme = "Synced";
            password_style = "random";
            hide_logo = true;
          };
          cursor.size = 24;
        };
        passwordlessSyncUsers = [username];
      };
      # for sync
      logind.enable = true;
    };

    environment.systemPackages = with pkgs; [
      catppuccin-cursors
      brightnessctl
      playerctl

      # plugin dependencies
      glib # Battery Widget
      yt-dlp # Youtube Search
    ];
  };
}
