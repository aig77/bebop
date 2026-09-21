{
  lib,
  config,
  inputs,
  ...
}: {
  options.flake.nixpkgs = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
  };

  config.flake.nixpkgs = {
    stable = inputs.nixpkgs-stable;
    unstable = inputs.nixpkgs-unstable;

    # Shared nixpkgs import config for both the host packages and the
    # alternate-channel imports.
    pkgsConfig = {
      allowUnfree = true;
      allowBroken = true;
    };

    defaultChannelFor = role:
      if role == "server"
      then "stable"
      else "unstable";

    channelFor = cfg:
      if cfg.nixpkgs == null
      then config.flake.nixpkgs.defaultChannelFor cfg.role
      else cfg.nixpkgs;

    srcFor = channel: inputs.${"nixpkgs-" + channel};

    # Exposes both channels on a host as pkgs.stable / pkgs.unstable. The base
    # channel aliases the host's own pkgs; the alternate channel is imported
    # fresh. system/config come from the module options (outside the package
    # set fixed point) so the overlay itself never forces its own prev/final.
    overlayModule = channel: {inputs, ...}: {
      nixpkgs.overlays = [
        (_: prev: let
          importChannel = src:
            import src {
              system = prev.stdenv.hostPlatform.system;
              config = config.flake.nixpkgs.pkgsConfig;
            };
        in {
          stable =
            if channel == "stable"
            then prev
            else importChannel inputs.nixpkgs-stable;
          unstable =
            if channel == "unstable"
            then prev
            else importChannel inputs.nixpkgs-unstable;
        })
      ];
    };
  };

  config.flake.assertions =
    lib.mapAttrsToList (name: cfg: {
      assertion = cfg.role == "client" || config.flake.nixpkgs.channelFor cfg == "stable";
      message = "host `${name}` has role `server` but selects `${config.flake.nixpkgs.channelFor cfg}`; servers must select `stable`";
    })
    config.configurations.nixos;
}
