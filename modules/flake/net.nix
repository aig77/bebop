{lib, ...}: {
  flake.modules.nixos.base = {config, ...}: {
    # Fleet network constants. Hosts are not listed here: every machine is on the
    # tailnet and resolves by MagicDNS, and the fleet is already declared in the
    # `configurations.nixos` registry. `net.addrOf` (schema in
    # modules/flake/var/nixos.nix) turns a hostname into a reachable address.
    options.net = lib.mkOption {
      type = lib.types.submodule {
        options = {
          subnet = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "192.168.68.0/24";
          };
          addrOf = lib.mkOption {
            type = lib.types.functionTo lib.types.str;
            default = name:
              if name == config.var.hostname
              then "localhost"
              else name;
          };
        };
      };
      default = {};
    };
  };
}
