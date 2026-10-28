_: {
  flake.modules.nixos.unbound-exporter = {
    config,
    pkgs,
    ...
  }: let
    port = config.ports.dns.unboundExporter;
  in {
    systemd.services.prometheus-unbound-exporter = {
      description = "Prometheus exporter for Unbound (letsencrypt)";
      wantedBy = ["multi-user.target"];
      after = ["unbound.service"];
      requires = ["unbound.service"];

      serviceConfig = {
        DynamicUser = true;
        SupplementaryGroups = ["unbound"];
        Restart = "on-failure";
        ExecStart = ''
          ${pkgs.prometheus-unbound-exporter}/bin/unbound_exporter \
            -unbound.host unix:///run/unbound/unbound.ctl \
            -unbound.ca /var/lib/unbound/unbound_server.pem \
            -unbound.cert /var/lib/unbound/unbound_control.pem \
            -unbound.key /var/lib/unbound/unbound_control.key \
            -web.listen-address 127.0.0.1:${toString port}
        '';
      };
    };


  };
}
