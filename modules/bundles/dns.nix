{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.dns = {
    imports = with nixos; [adguard unbound unbound-exporter];
  };
}
