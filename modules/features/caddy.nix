_: {
  flake.modules.nixos.caddy = {
    config,
    lib,
    pkgs,
    ...
  }: let
    publicServices = lib.filter (s: s.public) (lib.attrValues config.var.services);
    domain = config.sops.placeholder."cloudflare/service-domain";

    mkVhost = svc: ''
      ${svc.subdomain}.${domain} {
        reverse_proxy localhost:${toString svc.port} {
          header_up -X-Forwarded-For
        }
      }
    '';

    mkAuthVhost = svc: ''
      ${svc.subdomain}.${domain} {
        handle {
          import ${config.sops.templates."caddy-basic-auth".path}
          reverse_proxy localhost:${toString svc.port} {
            header_up -X-Forwarded-For
          }
        }
      }
    '';

    invidiousVhost = lib.optionalString (config.var.services ? invidious) ''
      invidious.${domain} {
        @authapi path /api/v1/auth/*
        handle @authapi {
          reverse_proxy localhost:${toString config.ports.invidious} {
            header_up -X-Forwarded-For
          }
        }
        handle {
          import ${config.sops.templates."caddy-basic-auth".path}
          reverse_proxy localhost:${toString config.ports.invidious} {
            header_up -X-Forwarded-For
          }
        }
      }
    '';

    otherVhosts = lib.concatMapStrings (
      svc:
        if svc.auth
        then mkAuthVhost svc
        else mkVhost svc
    ) (lib.filter (s: s.subdomain != "invidious") publicServices);
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
