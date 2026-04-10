_: {
  flake.modules.homeManager.base = {
    pkgs,
    lib,
    var,
    config,
    ...
  }: lib.mkIf (var.shell == "zsh") {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      syntaxHighlighting.styles = lib.mkIf (config.lib ? stylix) (
        let
          inherit (config.lib.stylix) colors;
        in {
          variable = "fg=#${colors.base0C}";
          assign = "fg=#${colors.base0C}";
          command = "fg=#${colors.base0D}";
          builtin = "fg=#${colors.base0D}";
          function = "fg=#${colors.base0D}";
          alias = "fg=#${colors.base0D}";
          single-quoted-argument = "fg=#${colors.base0B}";
          double-quoted-argument = "fg=#${colors.base0B}";
          path = "fg=#${colors.base0A},underline";
          single-hyphen-option = "fg=#${colors.base09}";
          double-hyphen-option = "fg=#${colors.base09}";
          unknown-token = "fg=#${colors.base08}";
          command-not-found = "fg=#${colors.base08}";
        }
      );

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

      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreAllDups = true;
        saveNoDups = true;
        findNoDups = true;
        append = true;
        share = true;
        ignoreSpace = true;
      };

      initContent = lib.mkMerge [
        (lib.mkBefore ''
          # Keybindings
          bindkey -e
          bindkey '^p' history-search-backward
          bindkey '^n' history-search-forward

          # Completion styling
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
          zstyle ':completion:*' keep-prefix true
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

          # fzf-tab
          zstyle ':completion:*:git-checkout:*' sort false
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
          zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept
          zstyle ':fzf-tab:*' use-fzf-default-opts yes
          zstyle ':fzf-tab:*' switch-group '<' '>'
        '')
        (lib.mkIf (config.lib ? stylix) ''
          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#${config.lib.stylix.colors.base03},bold"
        '')
      ];

      plugins = [
        {
          name = "zsh-vi-mode";
          src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
        }
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        }
      ];
    };

    programs = {
      direnv.enableZshIntegration = true;
      fzf.enableZshIntegration = true;
      ghostty.enableZshIntegration = true;
      starship.enableZshIntegration = true;
      zoxide.enableZshIntegration = true;
    };

    home.packages = with pkgs; [zsh-fzf-tab];
  };
}
