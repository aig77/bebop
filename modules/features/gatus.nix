_: {
  flake.modules.nixos.gatus = {
    config,
    lib,
    ...
  }: let
    mkProbeEndpoint = name: svc: let
      # Exactly one probe is set (asserted in the var schema).
      hp = svc.monitor;
      displayName =
        if hp.dns != null
        then "DNS ${svc.host}"
        else if svc.homepage.enable && svc.homepage.title != null
        then svc.homepage.title
        else lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
      addr = config.var.network.addrOf svc.host;
      base = {
        name = displayName;
        inherit (hp) interval;
        alerts = [
          {
            type = "discord";
            "failure-threshold" = hp.failureThreshold;
            "success-threshold" = hp.successThreshold;
          }
        ];
      };
    in
      if hp.http != null
      then
        base
        // {
          url = "http://${addr}:${toString svc.port}${hp.http.path}";
          conditions = hp.http.conditions;
        }
      else if hp.tcp != null
      then
        base
        // {
          url = "tcp://${addr}:${toString svc.port}";
          conditions = hp.tcp.conditions;
        }
      else
        base
        // {
          url = "${addr}:${toString svc.port}";
          dns = {
            "query-type" = hp.dns.queryType;
            "query-name" = hp.dns.queryName;
          };
          conditions = hp.dns.conditions;
        };

    generatedEndpoints =
      lib.mapAttrsToList mkProbeEndpoint
      (lib.filterAttrs (_: s: s.monitor.enable) config.var.services);
  in {
    var.services.gatus = {
      port = config.ports.gatus;
      monitor = {
        enable = true;
        http = {};
      };
      homepage = {
        enable = true;
        icon = "di:gatus";
      };
    };

    users.users.gatus = {
      isSystemUser = true;
      group = "gatus";
    };
    users.groups.gatus = {};

    sops = {
      secrets = {
        "discord/ein-webhook" = {};
        "tailscale/tailnet" = {};
      };
      templates."gatus.env" = {
        owner = "gatus";
        content = ''
          DISCORD_WEBHOOK_URL=${config.sops.placeholder."discord/ein-webhook"}
          TAILNET=${config.sops.placeholder."tailscale/tailnet"}
        '';
      };
    };

    services.gatus = {
      enable = true;
      environmentFile = config.sops.templates."gatus.env".path;
      settings = {
        web = {
          address = "127.0.0.1";
          port = config.ports.gatus;
        };
        storage = {
          type = "sqlite";
          path = "/var/lib/gatus/data.db";
        };
        ui = {
          title = "Bebop Health Dashboard";
          "login-subtitle" = null;
          header = "Bebop";
          "dashboard-heading" = "Is the ship running?";
          "dashboard-subheading" = null;
          logo = "https://www.clipartmax.com/png/full/132-1326331_zoom-edward-cowboy-bebop-png.png";
          link = "https://github.com/aig77/bebop";
          favicon.default = "https://www.vhv.rs/viewpic/hoobhxi_swordfish-png-cowboy-bebop-transparent-png/#";
          buttons = [
            {
              name = "Home";
              link = "https://${config.var.hostname}.\${TAILNET}";
            }
            {
              name = "GitHub";
              link = "https://github.com/aig77/bebop";
            }
          ];
          "custom-css" = ''
            /* Catppuccin Mocha */
            :root:root, :root:root.dark {
              --background: 240 21% 15%;
              --foreground: 226 64% 88%;
              --card: 237 16% 23%;
              --card-foreground: 226 64% 88%;
              --popover: 237 16% 23%;
              --popover-foreground: 226 64% 88%;
              --primary: 217 92% 76%;
              --primary-foreground: 240 21% 15%;
              --secondary: 235 13% 31%;
              --secondary-foreground: 226 64% 88%;
              --muted: 235 13% 31%;
              --muted-foreground: 230 13% 56%;
              --accent: 268 84% 81%;
              --accent-foreground: 240 21% 15%;
              --destructive: 343 81% 75%;
              --destructive-foreground: 240 21% 15%;
              --border: 237 16% 23%;
              --input: 237 16% 23%;
              --ring: 217 92% 76%;
            }
            .bg-success { background-color: #a6e3a1 !important; }
          '';
        };
        alerting.discord."webhook-url" = "\${DISCORD_WEBHOOK_URL}";
        endpoints = generatedEndpoints;
      };
    };
  };
}
