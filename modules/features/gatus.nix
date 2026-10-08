_: {
  flake.modules.nixos.gatus = {
    config,
    lib,
    ...
  }: let
    mkEndpoint = name: svc: let
      displayName =
        if svc.homepage.enable && svc.homepage.title != null
        then svc.homepage.title
        else lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
      url =
        if svc.monitor.type == "http"
        then "http://${config.var.network.addrOf svc.host}:${toString svc.port}${svc.monitor.path}"
        else "tcp://${config.var.network.addrOf svc.host}:${toString svc.port}";
    in {
      name = displayName;
      inherit url;
      interval = svc.monitor.interval;
      conditions = svc.monitor.conditions;
      alerts = [
        {
          type = "discord";
          "failure-threshold" = svc.monitor.failureThreshold;
          "success-threshold" = svc.monitor.successThreshold;
        }
      ];
    };

    generatedEndpoints =
      lib.mapAttrsToList mkEndpoint
      (lib.filterAttrs (_: s: s.monitor.enable) config.var.services);

    extraEndpoints = [
      {
        name = "Blocky DNS";
        url = "${config.var.network.addrOf "ed"}:53";
        dns = {
          "query-type" = "A";
          "query-name" = "example.com";
        };
        interval = "1m";
        conditions = ["[DNS_RCODE] == NOERROR"];
        alerts = [
          {
            type = "discord";
            "failure-threshold" = 2;
            "success-threshold" = 1;
          }
        ];
      }
    ];
  in {
    var.services.gatus = {
      port = config.ports.gatus;
      monitor = {
        enable = true;
        type = "http";
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
        endpoints = generatedEndpoints ++ extraEndpoints;
      };
    };
  };
}
