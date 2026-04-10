# Flake-Parts Infrastructure

## Contents

- [Overview](#overview)
- [Output Builders](#output-builders)
- [Systems](#systems)
- [Home Manager Bridges](#home-manager-bridges)
- [Variable Schema](#variable-schema)
- [Owner Metadata](#owner-metadata)
- [Dev Shell](#dev-shell)
- [Pre-Commit Hooks](#pre-commit-hooks)
- [Formatter](#formatter)

---

## Overview

Everything in `modules/flake/` defines the shape and wiring of the flake itself, not system configuration. These modules are not profiles and are not imported by hosts.

```
modules/flake/
├── flake-parts.nix           # Enables flake.modules.* option namespace
├── nixosConfigurations.nix   # NixOS system builder
├── darwinConfigurations.nix  # Darwin system builder
├── systems.nix               # Supported platforms
├── formatter.nix             # nix fmt (alejandra)
├── pre-commit.nix            # Git hooks
├── shell.nix                 # Dev shell
├── home-manager/             # NixOS/Darwin to HM bridges
│   ├── base.nix              # Minimal HM config every user gets
│   ├── nixos.nix             # Maps nixos profiles to HM profiles
│   └── darwin.nix            # Maps darwin profiles to HM profiles
├── var/                      # Variable schema
│   ├── default.nix           # NixOS var options
│   └── darwin.nix            # Darwin var options
└── owner/
    └── default.nix           # flake.meta.owner.username
```

---

## Output Builders

### `flake/nixosConfigurations.nix`

Defines the `configurations.nixos` option. Every NixOS host registers itself by contributing to `configurations.nixos.<hostname>.module`. This builder collects all registered hosts and calls `nixpkgs.lib.nixosSystem` for each, automatically including `sops-nix` and `stylix` NixOS modules.

### `flake/darwinConfigurations.nix`

Same pattern for Darwin. Automatically includes `home-manager`, `nix-homebrew`, `sops-nix`, and `stylix` Darwin modules.

**Why `inputs.self` is excluded from `specialArgs`:** nix-darwin evaluates `specialArgs` lazily in a context that causes infinite recursion when `inputs.self` is present. This is a known nix-darwin limitation. The workaround is `builtins.removeAttrs inputs ["self"]` in the builder. No Darwin module in this repo needs `inputs.self`, so nothing is lost. If a future module does need it, `config.flake.self` (available via flake-parts) is an alternative.

### `flake/flake-parts.nix`

Imports `flake-parts.flakeModules.modules`, enabling the `flake.modules.*` option namespace across all other files.

---

## Systems

### `flake/systems.nix`

```nix
systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
```

Declares supported platforms for `perSystem` outputs (dev shell, formatter, etc.).

---

## Home Manager Bridges

### `flake/home-manager/base.nix`

Contributes to `flake.modules.homeManager.base`. Sets `home.username` from `config.flake.meta.owner.username` and enables `programs.home-manager`. Every user gets this.

### `flake/home-manager/nixos.nix`

The NixOS-to-HM bridge. Reads `config.flake.modules.homeManager.*` at flake-parts level and wires them into `home-manager.users.<username>.imports` for each NixOS profile. Also passes `var` and `inputs` into HM's `extraSpecialArgs`.

| NixOS profile | HM profiles wired in |
|---------------|----------------------|
| `base` | `hm.base` |
| `desktop` | `hm.gui` |
| `hyprland` | `hm.hyprland`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle`, `hm.screenshot` |
| `hyprland-quickshell` | same as `hyprland` + quickshell |
| `niri` | `hm.niri`, `hm.waybar`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle` |
| `gnome` | `hm.gnome` |
| `gaming` | `hm.gaming` |

### `flake/home-manager/darwin.nix`

The Darwin-to-HM bridge. Wires `hm.base` and `hm.gui` into all Darwin configurations. Also passes `var` and `inputs` into HM's `extraSpecialArgs`.

---

## Variable Schema

### `flake/var/default.nix`

Contributes `options.var` to `flake.modules.nixos.base`. See [Architecture: Variable Schema](architecture.md#variable-schema) for the full option table.

### `flake/var/darwin.nix`

Same, contributed to `flake.modules.darwin.base`. Smaller set: `username`, `hostname`, `shell`, `terminal`, `browser`.

---

## Owner Metadata

### `flake/owner/default.nix`

```nix
flake.meta.owner.username = "arturo";
```

Single source of truth for the primary username. Used by `home-manager/base.nix` and the HM bridge modules. To change the username across the whole configuration, only this file needs updating.

---

## Dev Shell

### `flake/shell.nix`

Enter with `nix develop`. Provides: `age`, `git`, `neovim`, `nixd`, `sops`. Pre-commit hooks are installed automatically.

---

## Pre-Commit Hooks

### `flake/pre-commit.nix`

Three hooks run on `git commit` and `nix flake check`:

| Hook | Purpose |
|------|---------|
| `alejandra` | Auto-formats all `.nix` files |
| `statix` | Lints for antipatterns (warns on `{...}:` when `_:` suffices, etc.) |
| `deadnix` | Detects unused bindings in function argument patterns |

---

## Formatter

### `flake/formatter.nix`

Sets `alejandra` as the flake formatter. Run with:

```bash
nix fmt
```
