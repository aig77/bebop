_: {
  flake.modules.homeManager.gui = {
    inputs,
    lib,
    ...
  }: {
    imports = [inputs.nixcord.homeModules.nixcord];

    programs.nixcord = {
      enable = false;
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

    # Discord overwrites settings.json at runtime, replacing HM's symlink with a
    # real file. Clear the stale backup before HM's link check so it can
    # re-backup and re-link without conflicting.
    home.activation.discordSettingsCleanup = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      rm -f "$HOME/.config/discord/settings.json.hm-backup"
    '';
  };
}
