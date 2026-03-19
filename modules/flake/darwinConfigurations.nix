{
  lib,
  config,
  inputs,
  ...
}: {
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.module = lib.mkOption {
        type = lib.types.deferredModule;
      };
    });
    default = {};
  };

  config.flake.darwinConfigurations = lib.mapAttrs (_name: {module}:
    inputs.darwin.lib.darwinSystem {
      specialArgs = {inputs = builtins.removeAttrs inputs ["self"];};
      modules = [
        {
          nixpkgs.config = {
            allowUnfree = true;
            allowBroken = true;
          };
        }
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.sops-nix.darwinModules.sops
        inputs.stylix.darwinModules.stylix
        module
      ];
    })
  config.configurations.darwin;
}
