_: {
  # Per-host port table. ed runs the DNS stack and a metrics agent; it does
  # not run Prometheus, so there is no `prometheus` key here (that key would
  # read as a second owner of the prometheus service on jet).
  fleet.ports.ed = {
    adguard = 53;
    adguard-ui = {
      port = 4000;
      https = 443;
    };
    unbound = 4001;
    unboundExporter = 4002;
    nodeExporter = 3051;
    glanceAgent = 27973;
  };
}
