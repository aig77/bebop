_: {
  flake.modules.homeManager.screenshot = {
    pkgs,
    config,
    ...
  }: let
    screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
    timestamp = "$(date +%Y-%m-%d_%H-%M-%S)";
    shutterSound = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/camera-shutter.oga";

    screenshot-area = pkgs.writeShellScriptBin "screenshot-area" ''
      mkdir -p ${screenshotDir}
      ${pkgs.grimblast}/bin/grimblast --notify copysave area ${screenshotDir}/${timestamp}.png && \
      ${pkgs.pulseaudio}/bin/paplay ${shutterSound}
    '';

    screenshot-screen = pkgs.writeShellScriptBin "screenshot-screen" ''
      mkdir -p ${screenshotDir}
      ${pkgs.grimblast}/bin/grimblast --notify copysave screen ${screenshotDir}/${timestamp}.png && \
      ${pkgs.pulseaudio}/bin/paplay ${shutterSound}
    '';

    screenshot-window = pkgs.writeShellScriptBin "screenshot-window" ''
      mkdir -p ${screenshotDir}
      ${pkgs.grimblast}/bin/grimblast --notify copysave active ${screenshotDir}/${timestamp}.png && \
      ${pkgs.pulseaudio}/bin/paplay ${shutterSound}
    '';
  in {
    home.packages = with pkgs; [
      hyprshot
      slurp
      grim
      grimblast
      screenshot-area
      screenshot-screen
      screenshot-window
    ];
  };
}
