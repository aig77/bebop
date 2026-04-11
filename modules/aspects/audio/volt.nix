# WirePlumber defaults the Volt 476 to the pro-audio profile, which breaks
# normal apps (Discord, browsers, etc). This pins it to analog-surround-40
# on connect so it behaves like a standard audio device. Switch to pro-audio
# manually if needed for low-latency DAW work.
_: {
  flake.modules.nixos.volt = _: {
    services.pipewire.wireplumber.extraConfig."10-volt-profile" = {
      "monitor.alsa.rules" = [
        {
          matches = [{"device.name" = "alsa_card.usb-Universal_Audio_Volt_476_22142040012225-00";}];
          actions.update-props."device.profile" = "output:analog-surround-40+input:analog-surround-40";
        }
      ];
    };
  };
}
