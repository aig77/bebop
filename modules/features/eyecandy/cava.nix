_: {
  flake.modules.homeManager.cava = {
    lib,
    config,
    ...
  }: {
    programs.cava = {
      enable = true;
      settings = lib.mkIf (config.lib ? stylix) (
        let
          colors = config.lib.stylix.colors.withHashtag;
          blue = colors.base0D;
          teal = colors.base0C;
          green = colors.base0B;
          yellow = colors.base0A;
          peach = colors.base09;
          red = colors.base08;
          mauve = colors.base0E;
        in {
          color = {
            gradient = lib.mkForce 1;
            gradient_color_1 = lib.mkForce "'${blue}'";
            gradient_color_2 = lib.mkForce "'${teal}'";
            gradient_color_3 = lib.mkForce "'${green}'";
            gradient_color_4 = lib.mkForce "'${yellow}'";
            gradient_color_5 = lib.mkForce "'${peach}'";
            gradient_color_6 = lib.mkForce "'${red}'";
            gradient_color_7 = lib.mkForce "'${red}'";
            gradient_color_8 = lib.mkForce "'${mauve}'";
          };
        }
      );
    };
  };
}
