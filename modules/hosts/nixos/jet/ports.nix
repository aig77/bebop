_: {
  configurations.nixos.jet.module = {config, ...}: {
    ports = {
      glance = 3000;
      n8n = 3020;
      grafana = 3030;
      gatus = 3040;
      prometheus = config.mkPortGroup {
        base = 3050;
        names = ["server" "nodeExporter"];
      };
      dailyStoic = 3060;
      vaultwarden = 3070;
      actualBudget = 3080;
      subtrakr = 3090;
      # blockyHttp + nodeExporter are read from ed over the LAN; same numbers
      # ed binds (modules/hosts/nixos/ed/ports.nix).
      blockyHttp = 4000;
      open-webui = 4010;
      searx = 4020;
      forgejo = 4030;
      dbgate = 4040;
    };
  };
}
