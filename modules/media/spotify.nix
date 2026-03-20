_: {
  flake.modules.homeManager.gui = {inputs, ...}: {
    imports = [inputs.spicetify-nix.homeManagerModules.default];

    programs.spicetify = {enable = true;};
  };
}
