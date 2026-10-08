_: {
  flake.modules.nixos.n8n = {config, ...}: {
    var.services.n8n = {
      port = config.ports.n8n;
      backup.paths = ["/var/lib/n8n"];
      monitor = {
        enable = true;
        type = "http";
        path = "/healthz";
      };
      homepage = {
        enable = true;
        title = "n8n";
        icon = "di:n8n";
      };
    };

    sops = {
      secrets = {
        "discord/daily-stoic-bot-token" = {};
        "discord/ein-webhook" = {};
        "daily-stoic/api-key" = {};
      };

      templates."n8n.env" = {
        mode = "0444";
        content = ''
          DISCORD_TOKEN=${config.sops.placeholder."discord/daily-stoic-bot-token"}
          DISCORD_WEBHOOK=${config.sops.placeholder."discord/ein-webhook"}
          DAILY_STOIC_API_KEY=${config.sops.placeholder."daily-stoic/api-key"}
        '';
      };
    };

    services.n8n = {
      enable = true;
      environment = {
        GENERIC_TIMEZONE = "America/New_York";
        N8N_HOST = "127.0.0.1";
        # Loopback only: tailscale-http binds this same port on the tailnet IP.
        N8N_LISTEN_ADDRESS = "127.0.0.1";
        N8N_PORT = toString config.ports.n8n;
        N8N_SECURE_COOKIE = "false";
        N8N_BLOCK_ENV_ACCESS_IN_NODE = "false";
      };
    };

    systemd.services.n8n.serviceConfig.EnvironmentFile =
      config.sops.templates."n8n.env".path;
  };
}
