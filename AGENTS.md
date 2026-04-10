# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What This Is

**Bebop** is a Nix Flakes + flake-parts system configuration managing four machines from a single repo: two NixOS machines (x86_64 desktop, aarch64 server) and two macOS machines (aarch64-darwin).

## Build & Deploy Commands

```bash
# Apply NixOS configuration
sudo nixos-rebuild switch --flake .#faye
sudo nixos-rebuild switch --flake .#ed

# Apply macOS configuration
darwin-rebuild switch --flake .#ein
darwin-rebuild switch --flake .#spike

# Validate all modules (also runs pre-commit hooks: alejandra, statix, deadnix)
nix flake check

# Format all Nix files
nix fmt

# Enter dev shell (provides: age, git, neovim, nixd, sops)
nix develop
```

**Critical:** New `.nix` files must be `git add`ed before Nix can see them — import-tree uses git to discover files.

---

## Dendritic Pattern

This is the most important architectural concept for writing code in this repo.

### Auto-import via import-tree

`flake.nix` passes `./modules` to import-tree, which recursively collects every `.nix` file and merges them as a single flake-parts module. Every file is always imported — there are no conditional includes at the file level. Whether a file's config takes effect depends entirely on whether the host imports the relevant named profile.

### Named profiles, not direct configuration

Modules do **not** configure systems directly. Instead, they **expose named profiles** that hosts opt into:

```nix
# A module contributes to a named profile
_: {
  flake.modules.nixos.myfeature = {pkgs, config, ...}: {
    services.myfeature.enable = true;
  };
  flake.modules.homeManager.myfeature = {pkgs, config, ...}: {
    programs.myfeature.enable = true;
  };
}
```

Three profile namespaces exist:
- `flake.modules.nixos.<name>` — NixOS system modules
- `flake.modules.homeManager.<name>` — Home Manager modules
- `flake.modules.darwin.<name>` — nix-darwin modules

### deferredModule merge

All three namespaces use `deferredModule`. This means multiple files can all contribute to the same profile name — Nix merges them automatically. No explicit imports between files are needed.

### Hosts select profiles

Hosts import named profiles in their `imports.nix`. Modules never import hosts.

```nix
# modules/hosts/nixos/faye/imports.nix
{config, ...}: {
  configurations.nixos.faye.module = {
    imports = with config.flake.modules.nixos; [
      base desktop hyprland-quickshell amdgpu gaming docker tailscale volt
    ];
  };
}
```

### NixOS → Home Manager bridge

`modules/flake/home-manager/nixos.nix` maps NixOS profiles to HM profiles automatically. Importing a NixOS profile activates the corresponding HM profiles without the host listing them. For example, importing `nixos.desktop` automatically activates `hm.gui` for the user.

From within a HM module, `osConfig` accesses NixOS options. `config` accesses HM options only:

```nix
osConfig.sops.secrets.my-secret.path  # NixOS option
osConfig.var.hostname                  # NixOS var
config.programs.zsh.enable             # HM option
```

---

## Repository Structure

```
modules/
├── flake/      # Flake-parts infrastructure: output builders, HM bridges, var schema, dev shell
├── hosts/      # Per-machine definitions (nixos/ and darwin/)
├── aspects/    # Foundational system concerns applied broadly (nix, users, networking, boot, audio, etc.)
└── features/   # Opt-in capabilities selected per host (desktop envs, apps, services)
```

**Where to put new code:**
- New **aspect** (broadly-applied system concern): `modules/aspects/<name>/`
- New **feature** (opt-in capability): `modules/features/<name>/`
- New **host**: `modules/hosts/nixos/<hostname>/` or `modules/hosts/darwin/<hostname>/`
- Flake-parts **infrastructure** (output builders, bridges): `modules/flake/`

---

## Variable Schema

Hosts set typed variables; feature modules read them. Never hardcode hostnames, usernames, or paths that vary between hosts.

### NixOS (`modules/flake/var/default.nix`)

| Option | Default | Description |
|--------|---------|-------------|
| `var.username` | — | System username |
| `var.hostname` | — | Machine hostname |
| `var.shell` | — | `"zsh"` or `"fish"` |
| `var.terminal` | `"ghostty"` | Default terminal |
| `var.browser` | `"zen"` | Default browser |
| `var.location` | `""` | City for weather widgets |
| `var.launcher` | `"fuzzel"` | App launcher |
| `var.fileManager` | `"nautilus"` | File manager |
| `var.lock` | `"hyprlock"` | Lock screen command |
| `var.logout` | `"wlogout"` | Logout menu command |
| `var.wallpaperEngine` | `"swww"` | Wallpaper backend |
| `var.wallpaperPath` | `"$HOME/.cache/bebop/current-wallpaper"` | Runtime wallpaper symlink |

### Darwin (`modules/flake/var/darwin.nix`)

Smaller set: `username`, `hostname`, `shell`, `terminal`, `browser`.

---

## Module Function Forms

```nix
# No flake-parts inputs needed — use _: to satisfy statix
_: {
  flake.modules.nixos.myfeature = {pkgs, config, lib, ...}: {
    # NixOS module body
  };
}

# With flake-parts inputs
{config, inputs, lib, ...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [inputs.something.packages.${pkgs.system}.default];
  };
}
```

---

## Common Issues

**New file not picked up:** Run `git add <file>` — import-tree uses git to list files.

**`error: attribute 'X' missing` in HM module:** Use `osConfig.X` for NixOS options accessed from within HM. `config.X` inside HM refers to the HM config only.

**`statix` warning:** Replace `{...}:` with `_:` when no named args are used.

**`deadnix` warning:** Remove unused variables from the function argument pattern.

**OBS / Linux-only packages:** Guard with `lib.mkIf pkgs.stdenv.isLinux { ... }`.

---

## Full Documentation

- [Architecture](docs/architecture.md) — dendritic pattern, profiles, bridges, var schema, theming, secrets
- [Aspects](docs/modules/aspects.md) — foundational system modules reference
- [Features](docs/modules/features.md) — opt-in capability modules reference
- [Flake-Parts Infrastructure](docs/flake-parts.md) — output builders, bridges, dev shell
- [Hosts](docs/hosts/) — per-machine details (faye, ed, ein, spike)
- [How-To Guides](docs/howto/) — deploying, adding modules/hosts, secrets, age keys, inputs
