_: {
  flake.modules.homeManager.mako = {config, ...}: let
    colors = config.lib.stylix.colors.withHashtag;
  in {
    services.mako = {
      enable = true;

      defaultTimeout = 5000;
      ignoreTimeout = true;

      anchor = "top-right";
      margin = "20";
      padding = "15";

      width = 350;
      height = 150;
      borderSize = 2;
      borderRadius = 12;

      backgroundColor = "${colors.base00}dd";
      textColor = "${colors.base05}";
      borderColor = "${colors.base0D}";
      progressColor = "over ${colors.base02}";

      extraConfig = ''
        [urgency=low]
        border-color=${colors.base0D}

        [urgency=normal]
        border-color=${colors.base0D}

        [urgency=high]
        border-color=${colors.base08}
        default-timeout=0
      '';

      font = "${config.stylix.fonts.sansSerif.name} 11";

      iconPath = "${config.home.homeDirectory}/.local/share/icons";
      maxIconSize = 48;

      actions = true;
    };
  };
}
