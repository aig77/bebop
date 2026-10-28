_: {
  flake.modules.nixos.node-exporter = {config, ...}: {
    services.prometheus.exporters.node = {
      enable = true;
      port = config.ports.prometheus.nodeExporter;
    };
  };
}
