_: {
  flake.modules.nixos.unbound-exporter = {
    config,
    lib,
    pkgs,
    ...
  }: let
    port = config.ports.dns.unboundExporter;
    stateDir = config.services.unbound.stateDir or "/var/lib/unbound";
  in {
    systemd.services.prometheus-unbound-exporter = lib.mkIf (config.services.unbound.enable or false) {
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
            -unbound.ca ${stateDir}/unbound_server.pem \
            -unbound.cert ${stateDir}/unbound_control.pem \
            -unbound.key ${stateDir}/unbound_control.key \
            -web.listen-address 0.0.0.0:${toString port}
        '';
      };
    };
  };
}
