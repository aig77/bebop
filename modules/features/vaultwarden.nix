_: {
  flake.modules.nixos.vaultwarden = {
    config,
    pkgs,
    ...
  }: {
    var.services.vaultwarden = {
      port = config.ports.vaultwarden;
      expose = {subdomain = "vault";};
      backup = {
        paths = ["/var/lib/backups/vaultwarden"];
        prepareCommand = ''
          mkdir -p /var/lib/backups/vaultwarden
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 \
            ".backup '/var/lib/backups/vaultwarden/db.sqlite3'"
          cp -r /var/lib/vaultwarden/attachments \
            /var/lib/backups/vaultwarden/ 2>/dev/null || true
        '';
      };
      monitor = {
        enable = true;
        type = "tcp";
        interval = "1m";
        failureThreshold = 1;
        successThreshold = 1;
      };
      homepage = {
        enable = true;
        icon = "si:bitwarden";
      };
    };

    sops = {
      secrets = {
        "vaultwarden/admin-token" = {};
        "vaultwarden/smtp-api-key" = {};
        "cloudflare/service-domain" = {};
      };
      templates."vaultwarden.env" = {
        mode = "0400";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
          DOMAIN=https://vault.${config.sops.placeholder."cloudflare/service-domain"}
          SMTP_PASSWORD=${config.sops.placeholder."vaultwarden/smtp-api-key"}
          SMTP_FROM=vault@resend.${config.sops.placeholder."cloudflare/service-domain"}
        '';
      };
    };

    services.vaultwarden = {
      enable = true;
      environmentFile = config.sops.templates."vaultwarden.env".path;
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = config.ports.vaultwarden;
        SIGNUPS_ALLOWED = false;
        SHOW_PASSWORD_HINT = false;
        LOG_LEVEL = "warn";
        SMTP_HOST = "smtp.resend.com";
        SMTP_PORT = 465;
        SMTP_SECURITY = "force_tls";
        SMTP_USERNAME = "resend";
      };
    };
  };
}
