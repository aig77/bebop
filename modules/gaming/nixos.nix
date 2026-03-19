_: {
  flake.modules.nixos.gaming = _: {
    programs = {
      steam.enable = true;
      steam.gamescopeSession = {
        enable = true;
        args = [
          "-f"
          "-w 2560"
          "-h 1440"
          "--cursor-lock-enabled"
        ];
      };
      gamemode.enable = true;
    };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\\\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
}
