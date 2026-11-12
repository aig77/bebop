_: {
  configurations.nixos.ein.module = {
    config,
    pkgs,
    ...
  }: {
    home-manager.users.${config.var.username} = {
      imports = [];
      home = {
        homeDirectory = "/home/${config.var.username}";
        stateVersion = "25.05";
        packages = with pkgs; [lmstudio];
        sessionVariables = {
          EDITOR = "nvim";
          WALLPAPERS = "$HOME/Pictures/Wallpapers";
          XDG_CONFIG_HOME = "$HOME/.config";
        };
      };
    };
  };
}
