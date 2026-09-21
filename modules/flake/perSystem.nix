{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: {
    _module.args.pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};

    apps.deploy = {
      type = "app";
      program = "${pkgs.deploy-rs}/bin/deploy-rs";
    };

    apps.deploy-fleet = {
      type = "app";
      program = "${pkgs.writeShellScriptBin "deploy-fleet" ''
        exec ${pkgs.deploy-rs}/bin/deploy-rs --targets ".#ed" ".#jet" "$@"
      ''}/bin/deploy-fleet";
    };
  };
}
