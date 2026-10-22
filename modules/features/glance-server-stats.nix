_: {
  # Server stats for glance: the local machine directly, every other monitored
  # host through its glance-agent. Monitored hosts come from the observability
  # scrape targets, so adding a machine to the stack adds it here too.
  flake.modules.nixos.glance-server-stats = {
    config,
    lib,
    ...
  }: let
    remoteHosts = lib.unique (map (t: t.host) (
      lib.filter (t: t.job == "node" && t.host != config.var.hostname) config.observability.scrapeTargets
    ));

    mkRemote = host: {
      type = "remote";
      name = host;
      url = "http://${config.net.addrOf host}:${toString config.ports.glanceAgent}";
    };
  in {
    glance.extraWidgets.servers = [
      {
        type = "server-stats";
        title = "Servers";
        servers =
          [
            {
              type = "local";
              name = config.var.hostname;
            }
          ]
          ++ map mkRemote remoteHosts;
      }
    ];
  };
}
