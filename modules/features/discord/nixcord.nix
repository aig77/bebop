_: {
  flake.modules.homeManager.gui = {inputs, ...}: {
    imports = [inputs.nixcord.homeModules.nixcord];

    # Discord overwrites settings.json at runtime, replacing HM's symlink with a
    # real file. force=true prevents backup conflicts on subsequent activations.
    xdg.configFile."discord/settings.json".force = true;

    programs.nixcord = {
      enable = true;
      discord.settings = {
        MINIMIZE_TO_TRAY = false;
      };
      config = {
        frameless = true;
        plugins = {
          alwaysAnimate.enable = true;
          betterFolders.enable = true;
          fakeNitro.enable = true;
          imageZoom.enable = true;
          readAllNotificationsButton.enable = true;
        };
      };
    };
  };
}
