{config, ...}: {
  flake.modules.nixos = {
    # Thin shipper for every monitored machine: alloy ships systemd journal
    # logs to Loki, the node exporter exposes metrics for the stack host's
    # Prometheus to scrape, and the glance agent exposes system stats for the
    # stack host's server-stats widget. No storage, no dashboards.
    observability-agent = {
      imports = with config.flake.modules.nixos; [alloy node-exporter glance-agent];
    };

    # The observability stack: metrics, logs, dashboards, health checks. Runs
    # on one host, which also observes itself through observability-agent.
    # prometheus, grafana, loki and gatus are services: they are imported by
    # `base` because their ports are in the stack host's ports.nix.
    observability = {
      imports = with config.flake.modules.nixos; [
        observability-agent
        grafana-dashboards-node-exporter
        grafana-dashboards-loki
      ];
    };
  };
}
