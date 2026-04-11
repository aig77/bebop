_: {
  flake.modules.nixos.desktop = _: {
    security.rtkit.enable = true;
    services = {
      dbus.enable = true;
      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
    };
  };
}
