_: {
  flake.modules.homeManager.dunst = {
    lib,
    config,
    ...
  }: let
    colors = config.lib.stylix.colors.withHashtag;
    font = config.stylix.fonts.monospace.name;
  in {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          width = 300;
          height = 300;
          offset = "30x50";
          origin = "top-right";
          transparency = 10;
          frame_color = "${colors.base06}";
          corner_radius = 10;
          frame_width = 1;
          font = lib.mkForce font;
        };
      };
    };
  };
}
