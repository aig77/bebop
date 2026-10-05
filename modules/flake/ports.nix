{lib, ...}: {
  # Per-host port registry. Each host declares the ports its own services bind
  # (in modules/hosts/nixos/<host>/ports.nix) plus any remote ports it needs to
  # read, under a flat or grouped key. Values are plain numbers; a group is a
  # nested attrset. The collision assertion below rejects duplicates at eval.
  flake.modules.nixos.base = {config, ...}: {
    options = {
      ports = lib.mkOption {
        type = lib.types.attrsOf (lib.types.either lib.types.port (lib.types.attrsOf lib.types.port));
        default = {};
        description = "Ports bound or read by this host. Groups are nested attrsets.";
      };
      # Derive a group of sequential ports from a base. Order matters: append
      # new names at the end so existing ports do not shift.
      mkPortGroup = lib.mkOption {
        type = lib.types.functionTo (lib.types.attrsOf lib.types.port);
        default = {
          base,
          names,
        }:
          lib.listToAttrs (lib.imap0 (i: name: lib.nameValuePair name (base + i)) names);
        description = "Build a named port group starting at `base`.";
      };
    };

    config.assertions = let
      entries =
        lib.collect (e: e ? id)
        (lib.mapAttrsRecursive (path: port: {
            inherit port;
            id = lib.concatStringsSep "." path;
          })
          config.ports);
      collisions = lib.filterAttrs (_: es: lib.length es > 1) (lib.groupBy (e: toString e.port) entries);
    in [
      {
        assertion = collisions == {};
        message =
          "Port collisions: "
          + lib.concatStringsSep ";" (lib.mapAttrsToList
            (port: es: "${port} <- ${lib.concatMapStringsSep ", " (e: e.id) es}")
            collisions);
      }
    ];
  };
}
