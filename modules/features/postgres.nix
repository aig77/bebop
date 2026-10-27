_: {
  flake.modules.nixos.postgres = {
    config,
    pkgs,
    lib,
    ...
  }: {
    serviceRegistry.postgres = {
      port = config.ports.postgres.server;
      category = "Infrastructure";
      # A database is not an HTTP service: tailscale-http would wrap the PG
      # wire protocol in an HTTPS proxy. Monitor it, do not route it.
      serve = false;
      monitor = {
        enable = true;
        tcp = {};
      };
    };

    services = {
      postgresql = {
        enable = lib.mkForce true;
        package = pkgs.postgresql_16;
        port = config.ports.postgres.server;
        settings.listen_addresses = lib.mkForce "*";
      };
    };

    # Allow containers to connect over the podman bridge
    networking.firewall.interfaces.podman0.allowedTCPPorts = [config.ports.postgres.server];
  };
}
