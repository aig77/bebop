_: {
  flake.modules.homeManager.gui = {
    lib,
    config,
    inputs,
    pkgs,
    ...
  }: {
    options.programs.helium.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Helium browser";
    };

    config = lib.mkIf config.programs.helium.enable {
      home.packages = [inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default];

      home.file.".config/net.imput.helium/policies/managed/extensions.json".text = builtins.toJSON {
        ExtensionInstallForcelist = [
          "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # bitwarden
          "bkkmolkhemgaeaeggcmfbghljjjoofoh;https://clients2.google.com/service/update2/crx" # catppuccin mocha theme
          "eimadpbcbfnmbkopoojfekhnkhdbieeh;https://clients2.google.com/service/update2/crx" # dark reader
        ];
      };
    };
  };
}
