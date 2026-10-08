_: {
  flake.modules.nixos.glance = {
    config,
    lib,
    ...
  }: let
    # Local services are reached on this host's tailnet name; remote ones on
    # theirs. `svc.host` is the hostname, so the tailnet URL follows it.
    tsHostFor = svc:
      if svc.host == config.var.hostname
      then "\${TAILSCALE_HOST}"
      else "${svc.host}.\${TAILNET}";

    mkSite = name: svc: let
      title =
        if svc.homepage.title != null
        then svc.homepage.title
        else lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
      checkUrl =
        if svc.monitor.type == "http"
        then "http://${config.var.network.addrOf svc.host}:${toString svc.port}${svc.monitor.path}"
        else "http://${config.var.network.addrOf svc.host}:${toString svc.port}";
    in {
      inherit title;
      url =
        if svc.expose != null
        then "https://${svc.expose.subdomain}.\${SERVICE_DOMAIN}"
        else if svc.servePort == 443
        then "https://${tsHostFor svc}"
        else "https://${tsHostFor svc}:${toString (
          if svc.servePort != null
          then svc.servePort
          else svc.port
        )}";
      "check-url" = checkUrl;
      icon = svc.homepage.icon;
    };

    homepageServices = lib.filterAttrs (_: s: s.homepage.enable) config.var.services;
    publicSites = lib.mapAttrsToList mkSite (lib.filterAttrs (_: s: s.expose != null) homepageServices);
    privateSites = lib.mapAttrsToList mkSite (lib.filterAttrs (_: s: s.expose == null) homepageServices);
  in {
    var.services.glance = {
      port = config.ports.glance;
      servePort = 443;
    };

    sops = {
      secrets = {
        "tailscale/tailnet" = {};
        "cloudflare/service-domain" = {};
      };
      templates."glance.env" = {
        content = ''
          TAILSCALE_HOST=${config.var.hostname}.${config.sops.placeholder."tailscale/tailnet"}
          TAILNET=${config.sops.placeholder."tailscale/tailnet"}
          SERVICE_DOMAIN=${config.sops.placeholder."cloudflare/service-domain"}
        '';
      };
    };

    services.glance = {
      enable = true;
      settings = {
        server = {
          port = config.ports.glance;
          host = "127.0.0.1";
        };

        branding = {
          "favicon-url" = "https://www.realclipart.com/png/small/132-1326331_zoom-edward-cowboy-bebop-png.png";
        };

        theme = {
          "background-color" = "240 21% 15%";
          "contrast-multiplier" = 1.2;
          "primary-color" = "217 92% 83%";
          "positive-color" = "115 54% 76%";
          "negative-color" = "347 70% 65%";
        };

        pages = [
          {
            name = "Homelab";
            width = "slim";
            hide-desktop-navigation = true;
            center-vertically = true;
            columns = [
              {
                size = "full";
                widgets = [
                  {
                    type = "search";
                    autofocus = true;
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Public Services";
                    sites = publicSites;
                  }
                  {
                    type = "monitor";
                    cache = "1m";
                    title = "Private Services";
                    sites = privateSites;
                  }
                ];
              }
            ];
          }
        ];
      };
    };

    systemd.services.glance.serviceConfig.EnvironmentFile = lib.mkForce config.sops.templates."glance.env".path;
  };
}
