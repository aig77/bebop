_: {
  flake.modules.nixos.desktop = {pkgs, config, ...}: {
    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      cursor = {
        # name = "catppuccin-mocha-light-cursors";
        # package = pkgs.catppuccin-cursors.mochaLight;
        name = "catppuccin-mocha-dark-cursors";
        package = pkgs.catppuccin-cursors.mochaDark;
        size = 24;
      };

      icons = {
        dark = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    # Stylix installs the icon theme but doesn't expose it at a stable system path.
    # Adding it explicitly ensures icons are available at /run/current-system/sw/share/icons.
    environment.systemPackages = [ config.stylix.icons.package ];
  };
}
