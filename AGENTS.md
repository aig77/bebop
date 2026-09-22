# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

**Style note:** Do not use em dashes (—) in documentation or code comments.

**Read the docs.** The `docs/` tree is the single source of truth for architecture, modules, and workflows. If a concept is covered there, reference it rather than restating it here.

**NEVER USE THE SOPS COMMAND ON THE secrets.yaml AND VIEW THE SECRETS**

## What This Is

**Bebop** is a Nix Flakes + flake-parts system configuration managing five machines from a single repo: three NixOS machines (x86_64 desktop, x86_64 HTPC, aarch64 RPi server) and two macOS machines (aarch64-darwin).

## Build and Deploy

See [Deploying](docs/howto/deploying.md) for the full workflow. The essentials:

```bash
nh os switch                                        # NixOS
nh darwin switch -H ein                             # macOS
nix flake check                                     # validate all modules
nix fmt                                             # format all Nix files
nix develop                                         # dev shell (age, git, neovim, nixd, sops)
```

**Critical:** New `.nix` files must be `git add`ed before Nix can see them. import-tree uses git to discover files.

## Architecture

The config follows the dendritic pattern: modules expose named profiles, hosts opt into them. The full explanation, including the NixOS ↔ Home Manager bridge and the variable schema, is in [Architecture](docs/architecture.md). Read it before writing modules.

## Repository Structure

```text
modules/
├── flake/      # Flake-parts infrastructure: output builders, HM bridges, var schema, ports, dev shell
├── hosts/      # Per-machine definitions (nixos/ and darwin/)
├── aspects/    # Foundational system concerns always active for a machine type
├── bundles/    # Curated compositions of features (machines, shells, gui, wallpaper)
└── features/   # Atomic app and service configs
```

Where new code belongs:
- New feature (single app or service): `modules/features/<name>.nix`
- New feature spanning NixOS + HM: `modules/features/<name>/` with `nixos.nix`, `home.nix` etc.
- New bundle (group of features): `modules/bundles/<name>.nix`
- New aspect (foundational concern): `modules/aspects/<name>/`
- New host: `modules/hosts/nixos/<hostname>/` or `modules/hosts/darwin/<hostname>/`
- Flake-parts infrastructure: `modules/flake/`

## Module Function Forms

Modules are flake-parts modules exposing named profiles via `flake.modules.<namespace>.<name>`. Two forms, see [Architecture: Module Anatomy](docs/architecture.md#module-anatomy) for details:

```nix
_: {
  flake.modules.nixos.myfeature = {pkgs, config, ...}: {
    # NixOS module body
  };
}
```

```nix
{config, inputs, lib, ...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [inputs.something.packages.${pkgs.system}.default];
  };
}
```

Use `_:` when no flake-parts args are used (statix warns otherwise). Drop unused bindings from argument patterns (deadnix warns).

## Variable Schema

Hosts set typed variables via `var.*`; feature modules read them. Never hardcode hostnames, usernames, or paths that vary between hosts. The option definitions are the source of truth: `modules/flake/var/nixos.nix` (NixOS) and `modules/flake/var/darwin.nix` (Darwin). Ports work the same way via `modules/flake/ports.nix`.

## Common Issues

- **New file not picked up:** Run `git add <file>`. import-tree uses git to list files.
- **`error: attribute 'X' missing` in HM module:** Use `osConfig.X` for NixOS options from within HM. `config.X` inside HM is the HM config only.
- **OBS and other Linux-only packages:** Guard with `lib.mkIf pkgs.stdenv.isLinux { ... }`.

Fuller troubleshooting in [docs/howto/troubleshooting.md](docs/howto/troubleshooting.md).

## Full Documentation

- [Architecture](docs/architecture.md): dendritic pattern, profiles, bridges, var schema, theming, secrets
- [Aspects](docs/modules/aspects.md): foundational system modules reference
- [Features](docs/modules/features.md): opt-in capability modules reference
- [Bundles](docs/modules/bundles.md): curated feature group reference
- [Server Services](docs/modules/server.md): the var.services registry, exposure, auth, backups
- [Flake-Parts Infrastructure](docs/flake-parts.md): output builders, bridges, dev shell
- [Nixpkgs Channels](docs/howto/nixpkgs-channels.md): the stable/unstable channel split, base-by-role, per-package escapes
- [Hosts](docs/hosts/): per-machine details (spike, ein, faye, jet, ed)
- [Security](docs/howto/security.md): threat model, vulnix/trivy scanners
- [How-To Guides](docs/howto/): deploying, adding modules/hosts, secrets, age keys, inputs, ssh
