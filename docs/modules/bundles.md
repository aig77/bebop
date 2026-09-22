# Bundles

## What Are Bundles

Bundles are curated groups of features composed into higher-level profiles for easy reuse. Rather than importing individual features, hosts import a bundle that brings in a coherent set of related features.

Bundles live in `modules/bundles/` and can be single `.nix` files or directories with multiple variant files.

## Bundle vs. Feature vs. Aspect

| Situation | Use |
|-----------|-----|
| Group of features that always appear together for a machine type or desktop | Bundle |
| Single app or service that hosts opt into individually | Feature |
| System concern that every machine of a platform type must always have | Aspect |

Use a bundle when the same combination of features appears in multiple host `imports.nix` files. It reduces repetition and gives the combination a name that communicates intent. Don't create a bundle for a single feature or for a combination that only appears on one host - a direct import is simpler there.

See [Features](features.md) for the full list of atomic capabilities. See [Aspects](aspects.md) for foundational concerns.

## What the Bundles Are

The exact feature lists live in the bundle files, so this section only says what each bundle is for:

- **`machines.nix`** - machine-type profiles (`desktop`, `laptop`, `htpc`, `server`). Each composes the features that machine kind needs and wires in the appropriate HM shell. The `server` profile is the headless one, with no desktop stack.
- **`shells.nix`** - HM shell profiles (`shell`, `shell-lite`). The selected shell (zsh or fish) is chosen dynamically via `hm.${var.shell}`.
- **`gui.nix`** - the HM GUI profile: the terminal selected dynamically via `hm.${var.terminal}`, plus the always-on GUI apps.
- **`eyecandy.nix`** - terminal eye candy profiles (fastfetch, ASCII art packages).
- **`machines.nix`** `desktop` also owns the Noctalia shell (`noctalia-greeter`, the desktop services, and the `noctalia` HM profile). WM features (`hyprland`, `niri`) are imported separately by the host, so a machine can offer more than one session at the desktop manager.
- **`wallpaper.nix`** - waypaper GTK picker plus the wallpaper daemon, selected via `var.wallpaperEngine`.

## Where to See Real Composition

Rather than a hand-maintained example that goes stale, the actual composition lives in the host files:

- `modules/hosts/nixos/*/imports.nix` - which profiles and features each machine pulls in
- `modules/hosts/darwin/*/imports.nix` - same for macOS

Each host file is a few lines and is the ground truth. A new host is built by copying one of those and changing the imports.
