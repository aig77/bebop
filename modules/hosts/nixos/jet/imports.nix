{config, ...}: {
  configurations.nixos.jet.module = {inputs, ...}: {
    facter.reportPath = ./facter.json;
    imports =
      [inputs.nixos-facter-modules.nixosModules.facter]
      ++ (with config.flake.modules.nixos; [
        base
        server
        grub-server
        aarch64-builder

        backup
        caddy
        cloudflared
        dbgate
        tailscale-http
        trivy

        hetzner-storagebox

        actual-budget
        arr-stack
        daily-stoic
        forgejo
        gatus
        glance
        grafana
        n8n
        open-webui
        prometheus
        searx
        subtrakr
        vaultwarden
      ]);
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
