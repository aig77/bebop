_: {
  flake.modules.nixos.protonvpn = {config, ...}: {
    sops.templates."protonvpn-wg-conf" = {
      path = "/etc/wireguard/protonvpn.conf";
      mode = "0600";
      content = config.sops.placeholder."protonvpn/wg-conf";
    };
    systemd.tmpfiles.rules = ["d /etc/wireguard 0755 root root -"];
    # tunnel is a /32 on the host interface, strict rp_filter breaks the return path
    networking.firewall.checkReversePath = "loose";
  };
}
