_: {
  flake.modules.nixos.unbound-exporter = {config, ...}: {
    services.prometheus.exporters.unbound = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = config.ports.dns.unboundExporter;
    };
  };
}
