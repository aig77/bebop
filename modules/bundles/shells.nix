{config, ...}: let
  hm = config.flake.modules.homeManager;
in {
  flake.modules.homeManager.shell = {
    pkgs,
    var,
    ...
  }: {
    imports =
      [hm.${var.shell}]
      ++ (with hm; [
        claude
        direnv
        fzf
        git
        lazygit
        neovim
        opencode
        starship
        tmux
        vim
        zoxide
      ]);

    home.packages = with pkgs; [
      alejandra
      atac
      bat
      chezmoi
      curl
      cmake
      deadnix
      eza
      gcc
      gh
      glow
      gnumake
      jq
      manix
      nil
      ninja
      nixd
      nix-output-monitor
      nix-tree
      pkg-config
      ripgrep
      statix
      tldr
      unzip
      xz
      wget
      yazi
      zip
    ];
  };

  flake.modules.homeManager.shell-lite = {
    pkgs,
    var,
    ...
  }: {
    imports =
      [hm.${var.shell}]
      ++ (with hm; [
        fzf
        tmux
      ]);

    home.packages = with pkgs; [
      bat
      curl
      dig
      eza
      git
      jq
      lsof
      ncdu
      ripgrep
      rsync
      tldr
      unzip
      xz
      wget
      zip
    ];
  };
}
