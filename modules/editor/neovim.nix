_: {
  flake.modules.homeManager.base = _: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
    };
  };

  flake.modules.homeManager.nvimStylix = {
    lib,
    config,
    ...
  }: let
    enableStylix = false;
  in {
    stylix.targets.neovim.enable = false;

    # base16 themeing using stylix
    home.file = let
      priority = 900; # set loading priority
    in
      lib.mkIf enableStylix {
        ".config/nvim/lua/plugins/base16.lua".text = let
          colors = config.lib.stylix.colors.withHashtag;
        in ''
          return {
            "echasnovski/mini.base16",
            priority = ${toString priority},
            config = function()
              require('mini.base16').setup({ palette = {
                base00 = "${colors.base00}",
                base01 = "${colors.base01}",
                base02 = "${colors.base02}",
                base03 = "${colors.base03}",
                base04 = "${colors.base04}",
                base05 = "${colors.base05}",
                base06 = "${colors.base06}",
                base07 = "${colors.base07}",
                base08 = "${colors.base08}",
                base09 = "${colors.base09}",
                base0A = "${colors.base0A}",
                base0B = "${colors.base0B}",
                base0C = "${colors.base0C}",
                base0D = "${colors.base0D}",
                base0E = "${colors.base0E}",
                base0F = "${colors.base0F}",
              }})
            end
          }
        '';
      };
  };
}
