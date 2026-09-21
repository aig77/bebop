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

    # One command for both role=server hosts (ed then jet). Aborts on first
    # failure and rolls back any node already deployed in this run.
    apps.deploy-servers = {
      type = "app";
      program = "${pkgs.writeShellScriptBin "deploy-servers" ''
        exec ${pkgs.deploy-rs}/bin/deploy-rs --targets ".#ed" ".#jet" "$@"
      ''}/bin/deploy-servers";
    };
  };
}
