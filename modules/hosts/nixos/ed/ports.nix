_: {
  configurations.nixos.ed.module = {config, ...}: {
    ports = {
      prometheus = config.mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      blockyHttp = 4000;
      unbound = 5335;
    };
  };
}
