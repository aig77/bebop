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

        alloy
        loki

        trivy # container scanning

        actual-budget
        daily-stoic
        forgejo
        gatus
        glance
        grafana
        # invidious # temporarily remove since its down. plan on updating module with docker setup
        # invidious-status
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
