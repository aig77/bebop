_: {
  flake.modules.homeManager.fzf = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.fzf = {
      enable = true;
      # nushell integration asserts fzf >= 0.73 (stable ships 0.72).
      # pkgs.unstable.fzf is an identity alias on unstable-base hosts.
      package = pkgs.unstable.fzf;
      tmux.enableShellIntegration = true;
      colors = lib.mkIf (config.lib ? stylix) (
        let
          colors = config.lib.stylix.colors.withHashtag;
          accent = colors.base0D;
          foreground = colors.base05;
          muted = colors.base03;
        in
          lib.mkForce {
            "fg+" = accent;
            "bg+" = "-1";
            "fg" = foreground;
            "bg" = "-1";
            "prompt" = muted;
            "pointer" = accent;
            "scrollbar" = muted;
            "separator" = muted;
          }
      );
      defaultOptions = [
        "-i"
        "--margin=1"
        "--layout=reverse"
        "--border=none"
        "--info='hidden'"
      ];
    };
  };
}
