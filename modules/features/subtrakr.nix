_: {
  flake.modules.nixos.subtrakr = {
    config,
    pkgs,
    ...
  }: {
    var.services.subtrakr = {
      port = config.ports.subtrakr;
      backup = {
        paths = ["/var/lib/backups/subtrakr"];
        prepareCommand = ''
          mkdir -p /var/lib/backups/subtrakr
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/subtrakr/subtrakr.db \
            ".backup '/var/lib/backups/subtrakr/subtrakr.db'"
        '';
      };
      monitor = {
        enable = true;
        type = "http";
        path = "/healthz";
        conditions = ["[STATUS] == 200" "[BODY].status == healthy"];
      };
      homepage = {
        enable = true;
        icon = "mdi:credit-card-outline";
      };
    };

    # Unlike docker, podman errors instead of auto-creating a missing bind-mount source dir.
    systemd.tmpfiles.rules = ["d /var/lib/subtrakr 0755 root root -"];

    virtualisation = {
      podman.enable = true;
      oci-containers.containers = {
        subtrakr = {
          image = "ghcr.io/bscott/subtrackr:latest";
          ports = ["127.0.0.1:${toString config.ports.subtrakr}:8080"];
          volumes = ["/var/lib/subtrakr:/app/data"];
          environment = {
            GIN_MODE = "release";
            DATABASE_PATH = "/app/data/subtrakr.db";
          };
        };
      };
    };
  };
}
