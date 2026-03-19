{
  config,
  pkgs,
  ...
}: let
  modulesPath = ../../../modules;
in {
  imports = [
    # Programs
    (modulesPath + /home/programs/fetch)
    (modulesPath + /home/programs/ghostty)
    (modulesPath + /home/programs/git)
    (modulesPath + /home/programs/lazygit)
    (modulesPath + /home/programs/neovim)
    (modulesPath + /home/programs/obsidian)
    (modulesPath + /home/programs/shell)
    (modulesPath + /home/programs/spotify)
    (modulesPath + /home/programs/vim)
    (modulesPath + /home/programs/zen)
    ./variables.nix
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/Users/" + config.var.username;

    # Can't be installed with brew
    packages = with pkgs; [
      claude-code
      opencode
    ];

    sessionVariables = {
      EDITOR = "nvim";
      XDG_CONFIG_HOME = "$HOME/.config";
    };

    file = {};

    # https://nixos.wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.11";
  };

  # Let home manager install and manage itself
  programs.home-manager.enable = true;
}
