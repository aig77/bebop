{lib, ...}: {
  flake.modules.nixos.base = {
    # TODO: make ports a per-host registry instead of a global one.
    # Replace these per-port mkOptions with:
    #   options.ports = lib.mkOption {
    #     type = lib.types.attrsOf lib.types.port;
    #     default = {};
    #   };
    #   config.assertions = [
    #     {
    #       assertion =
    #         lib.unique (lib.attrValues config.ports) == lib.attrValues config.ports;
    #       message = "Duplicate port values in ports registry: ${toString config.ports}";
    #     }
    #   ];
    # Assertion enforces no dupes in the port map
    # Then declare values per host: jet/ports.nix (forgejo, vaultwarden,
    # prometheus, nodeExporter, blockyHttp, etc) and ed/ports.nix
    # (prometheus, nodeExporter, blockyHttp for prometheus-client).
    # jet's prometheus feature scrapes ed's exporters, so jet must also
    # declare nodeExporter + blockyHttp. Missing registration fails loud
    # at eval instead of silently using a global default.
    options.ports = {
      glance = lib.mkOption {
        type = lib.types.port;
        default = 3000;
      };
      invidious = lib.mkOption {
        type = lib.types.port;
        default = 3010;
      };
      invidiousCompanion = lib.mkOption {
        type = lib.types.port;
        default = 3011;
      };
      invidiousStatus = lib.mkOption {
        type = lib.types.port;
        default = 3012;
      };
      n8n = lib.mkOption {
        type = lib.types.port;
        default = 3020;
      };
      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3030;
      };
      gatus = lib.mkOption {
        type = lib.types.port;
        default = 3040;
      };
      prometheus = lib.mkOption {
        type = lib.types.port;
        default = 3050;
      };
      nodeExporter = lib.mkOption {
        type = lib.types.port;
        default = 3051;
      };
      dailyStoic = lib.mkOption {
        type = lib.types.port;
        default = 3060;
      };
      vaultwarden = lib.mkOption {
        type = lib.types.port;
        default = 3070;
      };
      actualBudget = lib.mkOption {
        type = lib.types.port;
        default = 3080;
      };
      subtrakr = lib.mkOption {
        type = lib.types.port;
        default = 3090;
      };
      # this stays at 4000 no matter what
      blockyHttp = lib.mkOption {
        type = lib.types.port;
        default = 4000;
      };
      open-webui = lib.mkOption {
        type = lib.types.port;
        default = 4010;
      };
      searx = lib.mkOption {
        type = lib.types.port;
        default = 4020;
      };
      forgejo = lib.mkOption {
        type = lib.types.port;
        default = 4030;
      };
      dbgate = lib.mkOption {
        type = lib.types.port;
        default = 4040;
      };
      unbound = lib.mkOption {
        type = lib.types.port;
        default = 5335;
      };
    };
  };
}
