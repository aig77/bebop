{config, ...}: {
  configurations.nixos.jet.module = {inputs, ...}: {
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        base
        server
        server-public
        server-private
        grub-server
        aarch64-builder

        postgres
        postgres-exporter
        grafana-dashboards-postgres
        grafana-dashboards-unbound
        backup
        dbgate
        hermes-readonly

        trivy # container scanning

        actual-budget
        daily-stoic
        forgejo
        n8n
        open-webui
        searx
        subtrakr
        sure
        vaultwarden
      ]);
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
