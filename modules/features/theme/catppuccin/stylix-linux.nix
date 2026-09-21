{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
in {
  flake.modules.nixos.stylix-catppuccin = {pkgs, ...}: let
    # prebuilds catppuccin cursor to avoid building inkscape from source
    cursor = pkgs.stdenvNoCC.mkDerivation {
      pname = "catppuccin-cursors";
      version = "2.0.0";
      src = pkgs.fetchurl {
        url = "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-dark-cursors.zip";
        hash = "sha256-pNl2SRvbGxMRst6IMnytPxxmwtnaiW4MVjYqZgyAJYU=";
      };
      nativeBuildInputs = [pkgs.unzip];
      installPhase = ''
        runHook preInstall
        unzip "$src"
        install -dm755 "$out/share/icons"
        mv catppuccin-mocha-dark-cursors "$out/share/icons/"
        runHook postInstall
      '';
      meta = {
        description = "Catppuccin Mocha dark cursor theme (prebuilt)";
        homepage = "https://github.com/catppuccin/cursors";
        license = pkgs.lib.licenses.gpl2;
        platforms = pkgs.lib.platforms.linux;
      };
    };
  in {
    # Scoped to desktop only to avoid breaking server hosts that lack stylix options
    imports = [inputs.stylix.nixosModules.stylix];

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
        name = "catppuccin-mocha-dark-cursors";
        package = cursor;
        size = 24;
      };

      icons = {
        enable = true;
        dark = "Papirus-Dark";
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "blue";
        };
      };
    };

    home-manager.users.${username}.imports = [hm.stylix-catppuccin];
  };

  flake.modules.homeManager.stylix-catppuccin = {
    config,
    pkgs,
    lib,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    font = config.stylix.fonts.monospace.name;
  in {
    home.file.".config/colors/colors.json".text = builtins.toJSON {
      inherit
        (colors)
        base00
        base01
        base02
        base03
        base04
        base05
        base06
        base07
        base08
        base09
        base0A
        base0B
        base0C
        base0D
        base0E
        base0F
        ;
      inherit font;
    };

    gtk.theme = lib.mkForce {
      package = pkgs.catppuccin-gtk.override {
        accents = ["blue"];
        size = "standard";
        variant = "mocha";
      };
      name = "catppuccin-mocha-blue-standard";
    };
  };
}
