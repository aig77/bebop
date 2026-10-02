_: let
  remoteBuilder = {
    lib,
    config,
    ...
  }: {
    options.remote-builder = {
      host = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      systems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["aarch64-linux"];
      };
      key = lib.mkOption {
        type = lib.types.str;
        default = "${config.var.home}/.ssh/id_ed25519";
      };
    };

    config.nix = {
      distributedBuilds = true;
      buildMachines = lib.mkIf (config.remote-builder.host != null) (
        map (system: {
          inherit system;
          hostName = config.remote-builder.host;
          sshUser = "root";
          sshKey = config.remote-builder.key;
          maxJobs = 2;
          protocol = "ssh-ng";
        })
        config.remote-builder.systems
      );
      settings.builders-use-substitutes = true;
    };
  };
in {
  flake.modules.nixos.remote-builder = remoteBuilder;
  flake.modules.darwin.remote-builder = remoteBuilder;
}
