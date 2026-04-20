_: {
  configurations.nixos.julia.module = {
    config,
    pkgs,
    ...
  }: {
    home-manager.users.${config.var.username} = {
      home = {
        homeDirectory = "/home/${config.var.username}";
        stateVersion = "25.05";
        packages = with pkgs; [
          amdgpu_top
          bitwarden-desktop
          mission-center
          networkmanagerapplet
          pavucontrol
          qpwgraph
          vlc
        ];
        sessionVariables = {
          EDITOR = "nvim";
          WALLPAPERS = "$HOME/Pictures/Wallpapers";
          XDG_CONFIG_HOME = "$HOME/.config";
        };
      };
    };
  };
}
