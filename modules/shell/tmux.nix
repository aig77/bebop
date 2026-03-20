_: {
  flake.modules.homeManager.base = {
    pkgs,
    var,
    ...
  }: {
    programs.tmux = {
      enable = true;
      shell = "${pkgs.${var.shell}}/bin/${var.shell}";
      clock24 = true;
      keyMode = "vi";
      baseIndex = 1;
      mouse = true;
      sensibleOnTop = true;
      prefix = "C-space";

      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        yank
      ];

      extraConfig = ''
        set -g default-command "${pkgs.${var.shell}}/bin/${var.shell} -l"
        set-option -sa terminal-overrides ",xterm*:Tc"

        bind -n M-H previous-window
        bind -n M-L next-window

        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        bind | split-window -h
        bind _ split-window -v
      '';
    };
  };
}
