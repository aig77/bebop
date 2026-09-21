{
  lib,
  config,
  inputs,
  ...
}: {
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options = {
        module = lib.mkOption {
          type = lib.types.deferredModule;
        };
        role = lib.mkOption {
          type = lib.types.enum ["client" "server"];
          default = "client";
        };
        nixpkgs = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum ["stable" "unstable"]);
          default = null;
        };
      };
    });
    default = {};
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (
      _name: cfg: let
        channel = config.flake.nixpkgs.channelFor cfg;
        channelModule = config.flake.nixpkgs.overlayModule channel;
        pkgsConfig = config.flake.nixpkgs.pkgsConfig;
      in
        (config.flake.nixpkgs.srcFor channel).lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            {nixpkgs.config = pkgsConfig;}
            channelModule
            inputs.sops-nix.nixosModules.sops
            cfg.module
          ];
        }
    )
    config.configurations.nixos;
}
