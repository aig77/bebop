_: {
  flake.modules.nixos.base = {
    config,
    inputs,
    lib,
    pkgs,
    ...
  }: {
    nix = {
      nixPath = ["nixpkgs=${inputs.nixpkgs}"];
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes" "pipe-operators"];
        trusted-users = ["root" config.var.username];
        substituters = [
          "https://cache.nixos.org"
          "https://devenv.cachix.org"
          "https://hyprland.cachix.org"
          "https://niri.cachix.org"
          "https://nix-community.cachix.org"
          "https://numtide.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "niri.cachix.org-1:Wv0Om60S7fSdV8Zk3SAnR1BkeE7CidN9sMny03u0T88="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        ];
      };

      gc = lib.mkIf pkgs.stdenv.isLinux {
        automatic = true;
        persistent = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
  };
}
