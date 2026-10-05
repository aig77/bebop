_: {
  flake.modules.nixos.caddy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    local = svc: svc.host == config.var.hostname;
    exposedServices = lib.filter (svc: svc.expose != null && local svc) (lib.attrValues config.var.services);
    domain = config.sops.placeholder."cloudflare/service-domain";

    target = svc: "${config.var.network.addrOf svc.host}:${toString svc.port}";

    mkVhost = svc: ''
      ${svc.expose.subdomain}.${domain} {
        reverse_proxy ${target svc} {
          header_up -X-Forwarded-For
        }
      }
    '';

    mkAuthVhost = svc: ''
      ${svc.expose.subdomain}.${domain} {
        handle {
          import ${config.sops.templates."caddy-basic-auth".path}
          reverse_proxy ${target svc} {
            header_up -X-Forwarded-For
          }
        }
      }
    '';

    invidiousVhost =
      lib.optionalString (
        config.var.services ? invidious
        && local config.var.services.invidious
        && config.var.services.invidious.expose != null
      ) (let
        svc = config.var.services.invidious;
      in ''
        ${svc.expose.subdomain}.${domain} {
          @authapi path /api/v1/auth/*
          handle @authapi {
            reverse_proxy ${target svc} {
              header_up -X-Forwarded-For
            }
          }
          handle {
            import ${config.sops.templates."caddy-basic-auth".path}
            reverse_proxy ${target svc} {
              header_up -X-Forwarded-For
            }
          }
        }
      '');

    otherVhosts = lib.concatMapStrings (
      svc:
        if svc.expose.basicAuth
        then mkAuthVhost svc
        else mkVhost svc
    ) (lib.filter (s: s.expose.subdomain != "invidious") exposedServices);
  in {
    sops = {
      secrets = {
        "cloudflare/acme-token" = {};
        "cloudflare/service-domain" = {};
        "caddy/basic-auth-hash" = {};
        "caddy/basic-auth-user" = {};
      };
      templates = {
        "caddy.env" = {
          mode = "0400";
          owner = "caddy";
          content = ''
            CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare/acme-token"}
          '';
        };
        # Using a template embeds the raw bcrypt hash directly into Caddyfile syntax,
        # avoiding the base64 encoding required by Caddy's JSON/env-var path.
        "caddy-basic-auth" = {
          mode = "0400";
          owner = "caddy";
          content = ''
            basic_auth * {
              ${config.sops.placeholder."caddy/basic-auth-user"} ${config.sops.placeholder."caddy/basic-auth-hash"}
            }
          '';
        };
        "Caddyfile" = {
          mode = "0400";
          owner = "caddy";
          reloadUnits = ["caddy.service"];
          content = ''
            {
              acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
              default_bind 127.0.0.1 ::1
            }

            ${invidiousVhost}
            ${otherVhosts}
          '';
        };
      };
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          # To update: nix run nixpkgs#nix-prefetch-github -- caddy-dns cloudflare
          # Then get the version: nix shell nixpkgs#go --command go list -m github.com/caddy-dns/cloudflare@<rev>
          "github.com/caddy-dns/cloudflare@v0.2.4"
        ];
        # Hash is for the combined caddy+plugin source. To update: set hash = lib.fakeHash,
        # build, and copy the "got:" value from the hash mismatch error.
        hash = "sha256-dQvk6ezY6TQ1J7PjhCXnThF/SqVgPwBO8/RXzHCY+js=";
      };
      configFile = config.sops.templates."Caddyfile".path;
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.templates."caddy.env".path;

    # Ports 80/443 stay closed externally -- cloudflared reaches Caddy on localhost
  };
}
