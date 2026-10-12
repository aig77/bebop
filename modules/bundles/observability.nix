{config, ...}: {
  flake.modules.nixos = {
    # Thin shipper for every monitored machine: alloy ships systemd journal
    # logs to Loki, the node exporter exposes metrics for the stack host's
    # Prometheus to scrape. No storage, no dashboards.
    observability-agent = {
      imports = with config.flake.modules.nixos; [alloy prometheus-client];
    };

    # The observability stack: metrics, logs, dashboards, health checks. Runs
    # on one host, which also observes itself through observability-agent.
    observability = {
      imports = with config.flake.modules.nixos; [
        observability-agent
        prometheus
        grafana
        loki
        gatus
      ];
    };
  };
}
