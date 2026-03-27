_: {
  flake.modules.homeManager.base = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.fish = let
      fetchCommand = "${pkgs.krabby}/bin/krabby name umbreon -s --no-title | ${pkgs.fastfetch}/bin/fastfetch --file-raw -";
    in {
      enable = true;

      shellAliases = {
        ll = "ls -l";
        nrw = "sudo nixos-rebuild switch --flake .";
        nrt = "sudo nixos-rebuild test --flake .";
        ls = "eza --icons=always --no-quotes";
        tree = "eza --icons=always --tree --no-quotes";
        cat = "bat --theme=base16 --color=always --wrap=never";
        fetch = fetchCommand;
      };

      interactiveShellInit = ''
        set -g fish_greeting ""
        function fish_greeting
          ${fetchCommand}
        end

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
