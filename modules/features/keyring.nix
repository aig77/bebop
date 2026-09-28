_: {
  flake.modules.nixos.keyring = _: {
    services.gnome.gnome-keyring.enable = true;
  };
}
