{
  config,
  lib,
  pkgs,
  ...
}: let
  secretsDir = ../../secrets;
in {
  sops = {
    defaultSopsFile = secretsDir + /secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.users.users.${config.var.username}.home}/.config/sops/age/keys.txt";

    secrets = {
      git-email = {};
      openweather-api-key = {};
      weatherapi-key = {};
    };

    templates = lib.mkIf pkgs.stdenv.isLinux {
      "weatherapi.json" = {
        content = builtins.toJSON {
          weather_api_key = config.sops.placeholder."weatherapi-key";
        };
        mode = "0444";
        owner = config.users.users.${config.var.username}.name;
        inherit (config.users.users.${config.var.username}) group;
      };
    };
  };
}
