_: {
  flake.modules.nixos.daily-stoic = {
    config,
    inputs,
    pkgs,
    ...
  }: {
    imports = [inputs.daily-stoic.nixosModules.default];

    var.services.daily-stoic = {
      port = config.ports.dailyStoic;
      expose = {subdomain = "stoic";};
      backup = {
        paths = ["/var/lib/backups/daily-stoic" "/var/lib/daily-stoic/database.json"];
        prepareCommand = ''
          mkdir -p /var/lib/backups/daily-stoic
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/daily-stoic/stoic.db \
            ".backup '/var/lib/backups/daily-stoic/stoic.db'"
        '';
      };
      monitor = {
        enable = true;
        type = "http";
        path = "/health";
      };
      homepage = {
        enable = true;
        title = "Daily Stoic";
        icon = "si:bookstack";
      };
    };

    sops = {
      secrets = {
        "daily-stoic/api-key" = {};
        "daily-stoic/resend/api-key" = {};
        "daily-stoic/resend/email" = {};
        "daily-stoic/bootstrap-admin-email" = {};
        "cloudflare/service-domain" = {};
      };

      templates."daily-stoic.env" = {
        mode = "0444";
        content = ''
          API_KEY=${config.sops.placeholder."daily-stoic/api-key"}
          RESEND_API_KEY=${config.sops.placeholder."daily-stoic/resend/api-key"}
          RESEND_EMAIL=${config.sops.placeholder."daily-stoic/resend/email"}
          BASE_URL=https://stoic.${config.sops.placeholder."cloudflare/service-domain"}
          BOOTSTRAP_ADMIN_EMAIL=${config.sops.placeholder."daily-stoic/bootstrap-admin-email"}
        '';
      };
    };

    services.daily-stoic = {
      enable = true;
      port = config.ports.dailyStoic;
      environmentFile = config.sops.templates."daily-stoic.env".path;
    };
  };
}
