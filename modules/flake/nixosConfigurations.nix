{
  lib,
  config,
  inputs,
  ...
}: {
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.module = lib.mkOption {
        type = lib.types.deferredModule;
      };
    });
    default = {};
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (
      _name: {module}:
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs;};
          modules = [
            {
              nixpkgs.config = {
                allowUnfree = true;
                allowBroken = true;
              };
            }
            inputs.sops-nix.nixosModules.sops
            module
          ];
        }
    )
    config.configurations.nixos;
}
