_: {
  flake.modules.nixos.postgres = {
    pkgs,
    lib,
    ...
  }: {
    services.postgresql = {
      enable = lib.mkForce true;
      package = pkgs.postgresql_16;
      settings.listen_addresses = lib.mkForce "*";
    };

    # Allow containers to connect over the podman bridge
    networking.firewall.interfaces.podman0.allowedTCPPorts = [5432];
  };
}
