# Aspects

## What Are Aspects

Aspects are foundational system concerns applied to every machine of a given type. They define what the system is at a base level: things every NixOS or Darwin machine always has, regardless of what optional capabilities it uses.

Aspects live in `modules/aspects/` and contribute to `nixos.base` or `darwin.base`. They are not optional - every host of their category imports them.

Desktop-specific concerns (audio, bluetooth, theming, boot) are **not** aspects. They live in `features/` and are composed into machine bundles.

See [Features](features.md) for atomic opt-in capabilities and [Bundles](bundles.md) for curated feature groups.

## What the Aspects Cover

| Aspect | Contributes to | What it does |
|--------|----------------|--------------|
| `nix` | `nixos.base` | Nix daemon settings: flakes, optimise store, auto gc, trusted users, substituters |
| `users` | `nixos.base` | Primary user account from `var.username`, shell enablement, sudo |
| `networking` | `nixos.base` | Hostname from `var.hostname`, NetworkManager, timezone, locale, ssh |
| `secrets` | `nixos.base` | sops-nix wired to `secrets.yaml`, age key location, secret declarations |
| `darwin` | `darwin.base` | macOS system config: Dock, Finder, keyboard remapping, dark mode, Homebrew, sops-nix |

The exact settings live in `modules/aspects/`, so this table stays at the level of what each aspect is responsible for rather than reprinting its contents.

### Flake-level infrastructure

These live in `modules/flake/` rather than `aspects/` because they are flake-parts plumbing, not system concerns:

| Module | What it does |
|--------|--------------|
| `var` | Variable schema (`options.var.*`), contributed to base profiles |
| `ports` | Per-host port registry (`options.ports.*`), contributed to `nixos.base` |
| `network` | Network constants (`var.network`), contributed to `nixos.base` |
| `owner` | `flake.meta.owner.username`, the single place to set the primary username |
| home-manager bridges | Wires NixOS/Darwin profiles to Home Manager profiles |

See [Flake-Parts Infrastructure](../flake-parts.md) for details.
