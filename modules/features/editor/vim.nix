_: {
  flake.modules.homeManager.shell = {pkgs, ...}: {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [vim-airline vim-sensible];
      settings = {
        ignorecase = true;
        history = 1000;
        tabstop = 4;
        smartcase = true;
        expandtab = true;
      };
      extraConfig = ''
        set nocompatible
        filetype on
        filetype plugin on
        filetype indent on
        syntax on
        set number
        set shiftwidth=4
        set nobackup
        set scrolloff=10
        set nowrap
        set incsearch
        set showcmd
        set showmode
        set showmatch
        set hlsearch
        set wildmenu
        set wildmode=list:longest
        set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
      '';
    };
  };
}
