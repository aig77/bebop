_: {
  flake.modules.homeManager.gui = {
    pkgs,
    lib,
    ...
  }: {
    programs.obs-studio = {
      enable = true;
      plugins = lib.optionals pkgs.stdenv.isLinux (with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
      ]);
    };
  };
}
