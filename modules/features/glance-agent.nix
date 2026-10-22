_: {
  # Glance agent: a tiny HTTP JSON API exposing CPU / memory / disk, used by
  # glance's `server-stats` widget for remote machines. One runs on every
  # monitored host (observability-agent bundle); the glance host reads its own
  # machine directly and only needs the agent on the other hosts.
  #
  # The port stays off the LAN: only the tailnet reaches it, no auth token.
  flake.modules.nixos.glance-agent = {
    config,
    pkgs,
    ...
  }: {
    systemd.services.glance-agent = {
      description = "Glance agent: system metrics API for the server-stats widget";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.unstable.glance-agent}/bin/agent";
        Environment = ["PORT=${toString config.ports.glanceAgent}"];
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };
  };
}
