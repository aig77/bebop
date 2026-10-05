{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules = {
    nixos = {
      tailscale = {
        services.tailscale = {
          enable = true;
          extraSetFlags = ["--accept-routes"];
        };
      };

      # Joins the tailnet with the shared auth key. Reachable by MagicDNS but
      # advertises no routes. Remote (off-LAN) servers use this.
      tailscale-node = {config, ...}: {
        sops.secrets."tailscale/authkey" = {};

        services.tailscale.authKeyFile = config.sops.secrets."tailscale/authkey".path;
      };

      tailscale-router = {config, ...}: {
        imports = [nixos.tailscale-node];

        services.tailscale = {
          useRoutingFeatures = "server";
          extraUpFlags = ["--advertise-routes=${config.var.network.subnet}" "--reset"];
          openFirewall = true;
        };
      };

      # Server only: serve non-public services over the tailnet with HTTPS
      tailscale-http = {
        config,
        lib,
        pkgs,
        ...
      }: let
        local = svc: svc.host == config.var.hostname;
        privateServices = lib.filter (svc: svc.expose == null && local svc) (lib.attrValues config.var.services);
        tailscale = lib.getExe pkgs.tailscale;
        httpsPort = svc:
          if svc.servePort != null
          then svc.servePort
          else svc.port;
        serveCmd = svc: "${tailscale} serve --bg --https=${toString (httpsPort svc)} http://${config.var.network.addrOf svc.host}:${toString svc.port}";
      in {
        services.tailscale.enable = true;

        systemd.services.tailscale-https = lib.mkIf (privateServices != []) {
          description = "Tailscale HTTPS serve for private services";
          after = ["tailscaled.service" "tailscaled-autoconnect.service"];
          wants = ["tailscaled.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "5s";
            ExecStart = map serveCmd privateServices;
            ExecStop = "${tailscale} serve reset";
          };
        };

        assertions = [
          {
            assertion =
              lib.unique (map httpsPort privateServices) == map httpsPort privateServices;
            message = "Tailscale serve HTTPS ports must be unique across private services: ${toString (map httpsPort privateServices)}";
          }
        ];
      };
    };

    darwin.tailscale = {
      services.tailscale.enable = true;
    };
  };
}
