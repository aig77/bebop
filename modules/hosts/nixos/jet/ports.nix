_: {
  # Per-host port table. The host block is the placement: a key that matches a
  # service name in `fleet.services` means this host runs that service on that
  # port. Auxiliary ports (exporters, agents) use names that are not service
  # names. `https` is the tailnet HTTPS port the service is served on.
  fleet.ports.jet = {
    glance = {
      port = 3000;
      https = 443;
    };
    n8n = 3020;
    grafana = 3030;
    gatus = 3040;
    prometheus = 3050;
    nodeExporter = 3051;
    daily-stoic = 3060;
    vaultwarden = 3070;
    actual-budget = 3080;
    subtrakr = 3090;
    loki = 3160;
    open-webui = 4010;
    searx = 4020;
    forgejo = 4030;
    dbgate = 4040;
    sure = 4050;
    sureRedis = 4051;
    syncserver = 4060;
    postgres = 5432;
    postgresExporter = 5433;
    glanceAgent = 27973;
  };
}
