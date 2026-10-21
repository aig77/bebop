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
        if svc.monitor.http != null
        then "http://${config.net.addrOf svc.host}:${toString svc.port}${svc.monitor.http.path}"
        else "http://${config.net.addrOf svc.host}:${toString svc.port}";
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

    homepageServices = lib.filterAttrs (_: s: s.homepage.enable) config.serviceRegistry;

    # Left column holds the services reachable from the internet, right
    # column the tailnet-only ones. Exposure comes from `expose`, not from
    # the category.
    isWeb = svc: svc.expose != null;

    # Keep the registry key so titles can fall back to it.
    pairs = lib.mapAttrsToList (name: svc: {inherit name svc;}) homepageServices;

    # Categories become sections. lib.attrNames sorts them alphabetically,
    # so the enum order in the schema does not matter here.
    byCategory = web: lib.groupBy (p: p.svc.category) (lib.filter (p: isWeb p.svc == web) pairs);

    mkSection = web: category: {
      type = "monitor";
      title = category;
      cache = "1m";
      sites = lib.map (p: mkSite p.name p.svc) (byCategory web).${category};
    };

    sections = web: lib.map (mkSection web) (lib.attrNames (byCategory web));

    # The html widget renders `source` verbatim, with no card of its own. The
    # `widget` wrapper borrows the normal header styling and the spacing the
    # column applies between widgets; `justify-center` centers the icon.
    mkColumnTitle = icon: {
      type = "html";
      source = ''
        <div class="widget"><div class="widget-header justify-center" style="font-size:calc(var(--font-size-h4) * 2)"><h2 class="uppercase">${icon}</h2></div></div>
      '';
    };
  in {
    serviceRegistry.glance = {
      port = config.ports.glance;
      servePort = 443;
      category = "Infrastructure";
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

        # The monitor widget lays its sites out in a `dynamic-columns` grid,
        # which folds them side by side once the page column is wide. Pin it
        # to a single column so every service is its own row, and drop the
        # column borders that layout leaves behind.
        document.head = ''
          <style>
            .widget-type-monitor .dynamic-columns { --columns-per-row: 1 !important; }
            .widget-type-monitor .dynamic-columns > * { border-left: none; padding-left: 0; }
          </style>
        '';

        pages = [
          {
            name = "Homelab";
            width = "slim";
            desktop-navigation-width = "slim";
            hide-desktop-navigation = true;
            center-vertically = false;
            columns = [
              {
                size = "full";
                widgets = [(mkColumnTitle "🌐")] ++ sections true;
              }
              {
                size = "full";
                widgets = [(mkColumnTitle "🔒")] ++ sections false;
              }
            ];
          }
        ];
      };
    };

    systemd.services.glance.serviceConfig.EnvironmentFile = lib.mkForce config.sops.templates."glance.env".path;
  };
}
