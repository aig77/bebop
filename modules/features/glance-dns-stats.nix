_: {
  # A DNS dashboard for glance, using its native `dns-stats` widget in adguard
  # mode. AdGuard Home exposes the JSON it needs at `GET /control/stats`; the
  # web/API is unauthenticated but tailnet-only (see features/adguard.nix).
  #
  # Runs on the glance host (jet) and reads the remote AdGuard on ed over the
  # tailnet. Guarded on a registered `adguard` service so it disappears if DNS
  # ever moves.
  flake.modules.nixos.glance-dns-stats = {
    config,
    lib,
    ...
  }: {
    glance.extraWidgets.dns = lib.mkIf (config.serviceRegistry ? adguard) [
      {
        type = "dns-stats";
        service = "adguard";
        title = "DNS";
        hour-format = "24h";
        url = "http://${config.net.addrOf "ed"}:${toString config.ports.dns.http}/";
      }
    ];
  };
}
