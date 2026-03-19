_: {
  configurations.nixos.faye.module = {
    config,
    pkgs,
    inputs,
    ...
  }: {
    home-manager.users.${config.var.username} = {
      home = {
        homeDirectory = "/home/${config.var.username}";
        stateVersion = "25.05";
        packages = with pkgs; [
          amdgpu_top
          bitwarden-desktop
          brave
          inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs
          gnome-calculator
          httpie-desktop
          imv
          lmstudio
          mission-center
          networkmanagerapplet
          obsidian
          pavucontrol
          qpwgraph
          vlc
          claude-code
          opencode
          yazi
          rustc
          cargo
          rust-analyzer
          clippy
          rustfmt
          python3
          uv
          go
          gopls
          golangci-lint
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
