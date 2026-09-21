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

  config.flake.darwinConfigurations = lib.mapAttrs (_name: {module}: let
    darwinModule = config.flake.nixpkgs.overlayModule "unstable";
  in
    inputs.darwin.lib.darwinSystem {
      # nix-darwin evaluates specialArgs lazily in a way that causes infinite recursion
      # when inputs.self is present. Since no Darwin module needs inputs.self, it is
      # stripped here. NixOS does not have this issue.
      specialArgs = {inputs = builtins.removeAttrs inputs ["self"];};
      modules = [
        {nixpkgs.config = config.flake.nixpkgs.pkgsConfig;}
        darwinModule
        inputs.home-manager.darwinModules.home-manager
        inputs.mac-app-util.darwinModules.default
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.sops-nix.darwinModules.sops
        inputs.stylix.darwinModules.stylix
        module
      ];
    })
  config.configurations.darwin;
}
