_: {
  # Fleet network constants. Hosts are not listed here: every machine is on the
  # tailnet and resolves by MagicDNS, and the fleet is already declared in the
  # `configurations.nixos` registry. `var.network.addrOf` (schema in
  # modules/flake/var/nixos.nix) turns a hostname into a reachable address.
  flake.modules.nixos.base = {
    var.network.subnet = "192.168.68.0/24";
  };
}
