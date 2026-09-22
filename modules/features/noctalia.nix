{config, ...}: let
  inherit (config.flake.meta.owner) username;
  inherit (config.flake.modules) nixos;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.noctalia = {pkgs, ...}: {
    imports = [nixos.catppuccin-cursors];
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

    environment.systemPackages = [pkgs.catppuccin-cursors];

    home-manager.users.${username}.imports = [hm.noctalia];
  };

  flake.modules.homeManager.noctalia = {
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.noctalia.homeModules.default];
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
    home.packages = with pkgs; [playerctl brightnessctl];
  };
}
