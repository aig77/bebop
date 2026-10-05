{config, ...}: let
  inherit (config.flake.meta.owner) username;
  hm = config.flake.modules.homeManager;
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos = {
    desktop = _: {
      imports = with nixos; [
        base
        audio
        bluetooth
        stylix-catppuccin
        grub
        gui
        nix-ld
        noctalia
        thunar
      ];
    };

    laptop = _: {
      imports = with nixos; [
        desktop
        battery
        protonvpn
        swap-rctl-for-super
      ];
    };

    htpc = _: {
      imports = with nixos; [
        base
        audio
        bluetooth
        stylix-catppuccin
        grub
      ];
      home-manager.users.${username}.imports = with hm; [
        discord
        shell-lite
        zen
      ];
      # USB keyboard+touchpad combo support (e.g. Rii mini); libinput explicit for Jovian Wayland
      boot.kernelModules = ["hid_generic"];
      services.libinput.enable = true;
    };

    # Platform every server shares: health reporting, CVE scanning, and the
    # private (tailnet HTTPS) exposure path. Ingress and dashboards are opt-in
    # via server-public / server-private.
    server = {lib, ...}: {
      imports = with nixos; [healthchecks vulnix tailscale-http];
      services.getty.autologinUser = username;
      home-manager.users.${username}.imports = [hm.shell-lite];
      sops.age.keyFile = lib.mkForce "/etc/sops/age/keys.txt";
    };

    # Public ingress: Caddy + Cloudflare tunnel. Each host runs its own tunnel.
    server-public = _: {
      imports = with nixos; [caddy cloudflared];
    };

    # Private dashboards and metrics: homepage + health dashboard + scraping.
    server-private = _: {
      imports = with nixos; [glance gatus grafana prometheus];
    };
  };
}
