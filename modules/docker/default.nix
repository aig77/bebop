_: {
  flake.modules.nixos.docker = {lib, ...}: {
    virtualisation.docker = {
      enable = false;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    systemd.user.services.docker = {
      enable = true;
      wantedBy = lib.mkForce [];
    };
  };
}
