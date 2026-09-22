# prebuilds catppuccin cursor to avoid building inkscape from source
_: {
  flake.modules.nixos.catppuccin-cursors = {pkgs, ...}: {
    nixpkgs.overlays = [
      (_: _: {
        catppuccin-cursors = pkgs.stdenvNoCC.mkDerivation {
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
      })
    ];
  };
}
