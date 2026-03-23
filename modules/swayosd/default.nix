_: {
  flake.modules.homeManager.swayosd = {config, pkgs, ...}: let
    colors = config.lib.stylix.colors.withHashtag;
    font = config.stylix.fonts.sansSerif.name;
  in {
    services.swayosd.enable = true;

    xdg.configFile."swayosd/style.css".text = ''
      window#osd {
        background: transparent;
      }

      box {
        background-color: ${colors.base00}dd;
        border: 2px solid ${colors.base0D};
        border-radius: 12px;
        padding: 16px 24px;
        min-width: 280px;
      }

      image {
        color: ${colors.base05};
        -gtk-icon-size: 32px;
        margin-right: 12px;
      }

      label {
        color: ${colors.base05};
        font-family: "${font}";
        font-size: 11pt;
      }

      progressbar,
      progressbar > trough,
      progressbar > trough > progress {
        border-radius: 6px;
        min-height: 8px;
      }

      progressbar > trough {
        background-color: ${colors.base02};
        min-width: 200px;
      }

      progressbar > trough > progress {
        background-color: ${colors.base0D};
      }
    '';
  };
}
