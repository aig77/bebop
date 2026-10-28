_: {
  configurations.nixos.ed.module = {config, ...}: {
    ports = {
      prometheus = config.mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      # Remote Loki on jet, read by this host's alloy (`loki` feature).
      loki = 3160;
      dns = config.mkPortGroup {
        base = 4000;
        names = ["http" "unbound" "unboundExporter"];
      };
      # Glance agent metrics API, read from jet over the tailnet.
      glanceAgent = 27973;
    };

    # AdGuard Home admin UI. Serving it over the tailnet (https://ed.<tailnet>/)
    # makes the glance card link work; the API port itself stays plain HTTP and
    # is read directly over the tailnet by glance's DNS widget and gatus.
    serviceRegistry.adguard-ui = {
      port = config.ports.dns.http;
      servePort = 443;
      category = "Infrastructure";
    };
  };
}
