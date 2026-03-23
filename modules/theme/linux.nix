_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    stylix = let
      wallpapersPath = ../../assets/wallpapers;
    in {
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

      # image = pkgs.fetchurl {
      #   url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/hollow-knight.jpg";
      #   sha256 = "sha256-dX3Xtf/Ma9UCzLfmRxnxLMHNL+IBjT2U06ruPmj5rHw=";
      # };

      image = wallpapersPath + /Faye-Valentine-Wallpaper-Catppuccin.jpg;

      cursor = {
        name = "catppuccin-mocha-light-cursors";
        package = pkgs.catppuccin-cursors.mochaLight;
        size = 24;
      };

      icons = {
        dark = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };
  };
}
