_: {
  # Observability policy: which remote endpoints jet's Prometheus scrapes.
  # This is the stack host's choice, not a fleet fact, so it stays here. Every
  # port is read from the owner's fleet table instead of being copied.
  configurations.nixos.jet.module = {fleet, ...}: {
    observability.scrapeTargets = [
      {
        job = "node";
        host = "ed";
        port = fleet.portOf "ed" "nodeExporter";
      }
      {
        job = "unbound";
        host = "ed";
        port = fleet.portOf "ed" "unboundExporter";
      }
    ];
  };
}
