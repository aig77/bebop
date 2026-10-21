_: {
  configurations.nixos.ed.module = {config, ...}: {
    ports = {
      prometheus = config.mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      # Remote Loki on jet, read by this host's alloy (`loki` feature).
      loki = 3160;
      blockyHttp = 4000;
      unbound = 5335;
    };
  };
}
