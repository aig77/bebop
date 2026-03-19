_: {
  flake.modules.homeManager.gui = _: {
    programs.zathura = {
      enable = true;
      options = {
        recolor = true;
        recolor-keephue = true;
        guioptions = "sv";
        adjust-open = "width";
        statusbar-basename = true;
        render-loading = false;
        scroll-step = 120;
        selection-clipboard = "clipboard";
        selection-notification = true;
      };
    };
  };
}
