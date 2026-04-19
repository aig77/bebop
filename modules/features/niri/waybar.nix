_: {
  flake.modules.homeManager.niri = _: {
    programs.waybar.settings.mainBar = {
      layer = "top";

      modules-left = ["group/niriNav"];

      modules-center = [];

      modules-right = [
        "clock"
        "group/hardware"
        "group/systray"
        "wireplumber"
        "custom/exit"
      ];
    };
  };
}
