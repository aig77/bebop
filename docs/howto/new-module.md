# Adding a Module

## Contents

- [NixOS-Only Module](#nixos-only-module)
- [Home Manager-Only Module](#home-manager-only-module)
- [Both-Layer Module](#both-layer-module)
- [Making It Available to Hosts](#making-it-available-to-hosts)
- [Contributing to an Existing Profile](#contributing-to-an-existing-profile)
- [Naming Conventions](#naming-conventions)

---

## NixOS-Only Module

Create a `.nix` file anywhere in `modules/features/` (or `modules/aspects/` if it's a foundational concern), then `git add` it.

```nix
# modules/features/myfeature/default.nix
_: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
    services.something.enable = true;
  };
}
```

Then add the profile name to the host's `imports.nix`:
```nix
# modules/hosts/nixos/faye/imports.nix
{config, ...}: {
  configurations.nixos.faye.module = {
    imports = with config.flake.modules.nixos; [
      base desktop hyprland-quickshell amdgpu gaming docker tailscale volt
      myfeature  # add here
    ];
  };
}
```

---

## Home Manager-Only Module

To contribute to an existing HM profile (e.g., add a package to every machine's `hm.base`):

```nix
# modules/features/myapp/default.nix
_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.myapp];
  };
}
```

No host changes needed — any host that already imports `nixos.base` automatically gets `hm.base`, which now includes this file.

To create a new opt-in HM profile:

```nix
_: {
  flake.modules.homeManager.myapp = {pkgs, config, ...}: {
    programs.myapp.enable = true;
  };
}
```

Then wire it in `modules/flake/home-manager/nixos.nix` so the right NixOS profile activates it:
```nix
myapp = _: {
  home-manager.users.${username}.imports = [hm.myapp];
};
```

---

## Both-Layer Module

This is the dendritic pattern's strength — one directory, one concept, spanning both system and user config:

```nix
# modules/features/myapp/nixos.nix
_: {
  flake.modules.nixos.myapp = {pkgs, ...}: {
    services.myapp.enable = true;
    environment.systemPackages = [pkgs.myapp];
  };
}
```

```nix
# modules/features/myapp/home.nix
_: {
  flake.modules.homeManager.myapp = {pkgs, config, ...}: {
    programs.myapp = {
      enable = true;
      settings = { ... };
    };
  };
}
```

Wire the HM profile in `modules/flake/home-manager/nixos.nix` and add the NixOS profile to any host that needs it.

---

## Making It Available to Hosts

There are two ways a module takes effect:

1. **Contributing to an existing profile** — if you add to `nixos.base` or `hm.base`, every host that uses those profiles picks it up automatically. Use this for things every machine should have.

2. **New named profile** — if you create a new profile name, hosts must explicitly import it in their `imports.nix`. Use this for opt-in features.

---

## Contributing to an Existing Profile

Multiple files can all contribute to the same profile name — Nix merges them automatically. So to add something to, say, `nixos.desktop` without touching any existing file:

```nix
# modules/aspects/mynewthing/default.nix
_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
  };
}
```

This is valid. All hosts that import `nixos.desktop` now get this too.

---

## Naming Conventions

- Use `_:` (not `{...}:`) in the outer function when no flake-parts args are used — `statix` will warn otherwise.
- Remove unused bindings from function argument patterns — `deadnix` will warn on unused variables.
- Place new **aspects** (foundational, broadly-applied) in `modules/aspects/<name>/`.
- Place new **features** (opt-in capabilities) in `modules/features/<name>/`.
- Split by layer when needed: `nixos.nix` for system, `home.nix` for user, keeping them in the same directory.
- `git add` new files before running `nix flake check` — import-tree uses git to discover files.
