_: {
  flake.modules.nixos.searx = {config, ...}: {
    var.services.searx = {
      port = config.ports.searx;
      monitor = {
        enable = true;
        type = "http";
        path = "/healthz";
        conditions = ["[STATUS] == 200" "[BODY] == OK"];
      };
      homepage = {
        enable = true;
        title = "SearXNG";
        icon = "si:searxng";
      };
    };

    sops = {
      secrets."searx/secret-key" = {};

      templates."searx-env" = {
        mode = "0444";
        content = ''
          SEARX_SECRET_KEY=${config.sops.placeholder."searx/secret-key"}
        '';
      };
    };

    services.searx = {
      enable = true;
      redisCreateLocally = true;
      environmentFile = config.sops.templates."searx-env".path;
      settings = {
        server = {
          secret_key = "$SEARX_SECRET_KEY";
          port = config.ports.searx;
          bind_address = "127.0.0.1";
          limiter = false;
          image_proxy = true;
        };
        search = {
          safe_search = 0;
          autocomplete = "duckduckgo";
          formats = ["html" "json"];
        };
      };
    };
  };
}
