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

        backup
        dbgate

        trivy # container scanning

        actual-budget
        daily-stoic
        forgejo
        # invidious # temporarily remove since its down. plan on updating module with docker setup
        # invidious-status
        n8n
        open-webui
        searx
        subtrakr
        vaultwarden
      ]);
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
