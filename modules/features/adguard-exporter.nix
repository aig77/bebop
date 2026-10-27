_: {
  flake.modules.nixos.adguard-exporter = {config, ...}: {
    services.prometheus.exporters.adguardhome = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = config.ports.dns.adguardExporter;
      address = "http://127.0.0.1:${toString config.ports.dns.http}";
    };
  };
}
