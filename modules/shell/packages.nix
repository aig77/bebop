_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = with pkgs; [
      alejandra
      bat
      curl
      cmake
      deadnix
      eza
      fzf
      gcc
      gh
      git
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
      zip
    ];
  };
}
