_: {
  # Shared option for glance widgets contributed by feature modules, keyed by
  # page column ("dns", "servers"). Keeping it in its own options-only module
  # lets features contribute widgets without glance needing to know about the
  # individual services.
  flake.modules.nixos.glance-widgets = {
    lib,
    pkgs,
    ...
  }: {
    options.glance.extraWidgets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (pkgs.formats.yaml {}).type);
      default = {};
      description = "Extra widgets for a page column, keyed by column name (dns, servers).";
    };
  };
}
