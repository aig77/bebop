_: {
  configurations.darwin.ein.module = {
    config,
    pkgs,
    ...
  }: {
    home-manager.users.${config.var.username} = {
      home = {
        homeDirectory = "/Users/${config.var.username}";
        stateVersion = "24.11";
        packages = with pkgs; [claude-code opencode];
        sessionVariables = {
          EDITOR = "nvim";
          XDG_CONFIG_HOME = "$HOME/.config";
        };
      };
    };
  };
}
