{inputs, ...}: {
  imports = [inputs.git-hooks-nix.flakeModule];
  perSystem = {
    pre-commit = {
      check.enable = true;
      settings.hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };
  };
}
