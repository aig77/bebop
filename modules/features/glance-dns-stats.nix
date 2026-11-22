_: {
  # A DNS dashboard for glance, using its native `dns-stats` widget in adguard
  # mode. AdGuard Home exposes the JSON it needs at `GET /control/stats`; the
  # web/API is unauthenticated but tailnet-only (see features/adguard.nix).
  #
  # Runs on the glance host and reads the remote AdGuard on ed over the
  # tailnet. Guarded on the registered `adguard-ui` service so it disappears
  # if DNS ever moves.
  flake.modules.nixos.glance-dns-stats = {
    config,
    lib,
    ...
  }: {
    glance.extraWidgets.dns = lib.mkIf (builtins.hasAttr "adguard-ui" config.serviceRegistry) (let
      adguard = config.serviceRegistry."adguard-ui";
    in [
      {
        type = "dns-stats";
        service = "adguard";
        title = "DNS";
        hour-format = "24h";
        url = "http://${config.net.addrOf adguard.host}:${toString adguard.port}/";
      }
    ]);
  };
}
