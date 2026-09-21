_: {
  flake.modules.darwin.remote-builder = {
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
    };

    config.nix.settings = {
      builders-use-substitutes = true;
      buildMachines = lib.mkIf (config.remote-builder.host != null) (
        map (system: {
          inherit system;
          hostName = config.remote-builder.host;
          sshUser = "root";
          maxJobs = 2;
          protocol = "ssh-ng";
        })
        config.remote-builder.systems
      );
    };
  };
}
