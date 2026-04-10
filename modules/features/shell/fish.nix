_: {
  flake.modules.homeManager.base = {
    pkgs,
    lib,
    var,
    config,
    ...
  }: lib.mkIf (var.shell == "fish") {
    programs.fish = {
      enable = true;

      shellAliases =
        {
          ll = "ls -l";
          ls = "eza --icons=always --no-quotes";
          tree = "eza --icons=always --tree --no-quotes";
          cat = "bat --theme=base16 --color=always --wrap=never";
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          nrs = "sudo darwin-rebuild switch --flake .";
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          nrs = "sudo nixos-rebuild switch --flake .";
          nrt = "sudo nixos-rebuild test --flake .";
        };

      interactiveShellInit = ''
        set -g fish_greeting ""

        fish_vi_key_bindings

        bind -M insert \e\[A history-search-backward
        bind -M insert \e\[B history-search-forward
        bind \e\[A history-search-backward
        bind \e\[B history-search-forward

        bind -M insert \cp history-search-backward
        bind -M insert \cn history-search-forward
        bind \cp history-search-backward
        bind \cn history-search-forward

        if type -q fzf_configure_bindings
          fzf_configure_bindings --directory=\ct --git_log=\cl --git_status=\cg --history=\cr
        end

        set -U fish_history_save all
      '';

      shellInitLast = lib.mkIf (config.lib ? stylix) (
        let
          colors = config.lib.stylix.colors.withHashtag;
        in "set -g fish_color_param ${colors.base05}"
      );

      plugins = with pkgs.fishPlugins; [
        {inherit (fzf-fish) name src;}
        {inherit (autopair) name src;}
        {inherit (done) name src;}
        {inherit (sponge) name src;}
      ];
    };

    programs = {
      fzf.enableFishIntegration = true;
      ghostty.enableFishIntegration = true;
      starship.enableFishIntegration = true;
      zoxide.enableFishIntegration = true;
    };
  };
}
