{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  # AdGuard is a service, enabled by ed's ports.nix. This bundle is the rest of
  # the DNS stack: the recursive resolver and its exporter.
  flake.modules.nixos.dns = {
    imports = with nixos; [unbound unbound-exporter];
  };
}
