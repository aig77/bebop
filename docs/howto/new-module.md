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

Create a `.nix` file in `modules/features/` (or `modules/aspects/` if it's a foundational concern), then `git add` it.

```nix
# modules/features/myfeature/default.nix
_: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
    services.something.enable = true;
  };
}
```

Add the profile name to the host's `imports.nix`:
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

To add to an existing HM profile (e.g., give every machine a new package via `hm.base`):

```nix
# modules/features/myapp/default.nix
_: {
  flake.modules.homeManager.base = {pkgs, ...}: {
    home.packages = [pkgs.myapp];
  };
}
```

No host changes needed. Any host that imports `nixos.base` automatically gets `hm.base`, which now includes this.

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

One directory, one concept, spanning both system and user config:

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

Two paths:

1. **Contributing to an existing profile**: add to `nixos.base` or `hm.base` and every host picks it up automatically. Good for things every machine should have.

2. **New named profile**: create a new profile name and hosts import it explicitly in `imports.nix`. Good for opt-in features.

---

## Contributing to an Existing Profile

Multiple files can all contribute to the same profile name; Nix merges them. To add something to `nixos.desktop` without touching any existing file:

```nix
# modules/aspects/mynewthing/default.nix
_: {
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
  };
}
```

All hosts that import `nixos.desktop` now get this too.

---

## Naming Conventions

- Use `_:` in the outer function when no flake-parts args are used. `statix` warns on `{...}:` with no used bindings.
- Remove unused variables from function argument patterns. `deadnix` warns on unused bindings.
- New aspects go in `modules/aspects/<name>/`, new features in `modules/features/<name>/`.
- Split by layer when needed: `nixos.nix` for system config, `home.nix` for user config, in the same directory.
- `git add` new files before running `nix flake check`. import-tree uses git to discover files.
