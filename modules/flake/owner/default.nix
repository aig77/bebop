{lib, ...}: {
  options.flake.meta = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
  };

  config.flake.meta.owner = {
    username = "arturo";
  };
}
