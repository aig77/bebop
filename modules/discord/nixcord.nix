_: {
  flake.modules.homeManager.gui = {inputs, ...}: {
    imports = [inputs.nixcord.homeModules.nixcord];

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
