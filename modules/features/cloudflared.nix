_: {
  flake.modules.nixos.cloudflared = {
    config,
    lib,
    pkgs,
    ...
  }: let
    local = svc: svc.host == config.var.hostname;
    exposedServices = lib.filter (svc: svc.expose != null && local svc) (lib.attrValues config.var.services);
    domain = config.sops.placeholder."cloudflare/service-domain";
    ingressRules =
      lib.concatMapStrings (svc: ''
        - hostname: ${svc.expose.subdomain}.${domain}
          service: https://localhost
          originRequest:
            noTLSVerify: true
            originServerName: ${svc.expose.subdomain}.${domain}
      '')
      exposedServices;
  in {
    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
    };
    users.groups.cloudflared = {};

    sops = {
      secrets = {
        "cloudflare/${config.var.hostname}/tunnel-id" = {};
        "cloudflare/${config.var.hostname}/tunnel-credentials" = {
          mode = "0400";
          owner = "cloudflared";
        };
      };
      templates."cloudflared.yml" = {
        owner = "cloudflared";
        restartUnits = ["cloudflared.service"];
        content = ''
          tunnel: ${config.sops.placeholder."cloudflare/${config.var.hostname}/tunnel-id"}
          credentials-file: ${config.sops.secrets."cloudflare/${config.var.hostname}/tunnel-credentials".path}
          ingress:
          ${ingressRules}- service: http_status:404
        '';
      };
    };

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config=${config.sops.templates."cloudflared.yml".path} --no-autoupdate run";
        User = "cloudflared";
        Group = "cloudflared";
        Restart = "on-failure";
      };
    };
  };
}
