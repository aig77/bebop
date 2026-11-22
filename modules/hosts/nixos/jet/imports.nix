{config, ...}: {
  configurations.nixos.jet.module = {inputs, ...}: {
    facter.reportPath = ./facter.json;
    # Service features are enabled by modules/hosts/nixos/jet/ports.nix, not
    # here. This list is infrastructure: things that are not tied to a service
    # port (backup, exporters, dashboards, host tooling).
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        base
        server
        server-public
        server-private
        grub-server
        aarch64-builder

        backup
        grafana-dashboards-postgres
        grafana-dashboards-unbound
        hermes-readonly
        postgres-exporter

        trivy # container scanning
      ]);
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
