{inputs, ...}: {
  perSystem = {system, ...}: {
    _module.args.pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
  };
}
