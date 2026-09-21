{
  config,
  lib,
  inputs,
  ...
}: {
  options.flake.deploy = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
  };

  config.flake.deploy = {
    sshOpts = [
      "-o"
      "StrictHostKeyChecking=accept-new"
      "-o"
      "ControlMaster=auto"
      "-o"
      "ControlPersist=60"
    ];

    # One node per role=server host (ed, jet). Each inherits its host's base
    # nixpkgs channel and its own system; deploy-rs builds on the runner and
    # ships the closure. Jet is the central builder (see jet-builder feature).
    nodes =
      lib.mapAttrs (name: _cfg: let
        nixos = config.flake.nixosConfigurations.${name};
      in {
        hostname = nixos.config.networking.hostName;
        sshUser = "root";
        user = "root";
        activationTimeout = 600;
        remoteBuild = false;
        profiles.system.path =
          inputs.deploy-rs.lib.${nixos.pkgs.system}.activate.nixos nixos;
      })
      (lib.filterAttrs (_name: c: c.role == "server") config.configurations.nixos);
  };
}
