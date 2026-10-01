# Features

## What Are Features

Features are atomic apps and services that a host explicitly selects. Each one is a single, self-contained concern: an app, a service, a component. Features are the building blocks that bundles compose together.

Features live in `modules/features/` and contribute to named profiles that hosts or bundles import. A feature is usually a single `.nix` file, or a directory when a concept genuinely spans multiple files (for example, a NixOS-side file and a Home Manager-side file for the same program).

See [Aspects](aspects.md) for foundational concerns and [Bundles](bundles.md) for curated feature groups.

## Feature vs. Bundle vs. Aspect

| Situation | Use |
|-----------|-----|
| Single app or service that hosts opt into individually | Feature |
| Group of features that always appear together for a machine type or desktop | Bundle |
| System concern that every machine of a platform type must always have | Aspect |

When in doubt, start with a feature. Bundles are an optimization you apply once you see the same combination repeated across host `imports.nix` files.

## How a Feature Is Shaped

Every feature contributes to at least one named profile via `flake.modules`. A NixOS feature might look like:

```nix
_: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
    services.something.enable = true;
  };
}
```

Features that span NixOS and Home Manager own their own wiring: the NixOS side adds `home-manager.users.${username}.imports = [hm.<name>]` in the same directory, instead of centralizing the mapping. The full patterns are in [Adding a Module](../howto/new-module.md).

The list of actual features is `modules/features/` itself, so this page won't enumerate them and go stale. By category, what's in there:

- **Desktop environments** - full compositor/WM setup (`hyprland`) owning its system enablement and HM config.
- **Desktop components** - bars, launchers, lock/idle daemons, wallpaper, screenshot, file manager, theming.
- **System services** - display manager, audio, bluetooth, boot, GPU drivers, gaming, docker, tailscale, and the self-hosted stack.
- **Server services** - caddy, cloudflared, dns, backup, and the individual self-hosted apps. See [Server Services](server.md).
- **Applications** - Home Manager modules for shells, editors, terminals, browsers, and GUI apps.
- **Darwin-specific** - macOS-flavored extras.

For per-feature details, read the file. For how they compose, see [Bundles](bundles.md).

## Using Config Files Without NixOS

Some config directories in this repo (e.g. `modules/features/neovim/nvim/`) are usable standalone on any machine without deploying the full NixOS config. Use sparse checkout to clone only what you need:

```bash
git clone --no-checkout --filter=blob:none https://github.com/aig77/bebop ~/.config/bebop
cd ~/.config/bebop
git sparse-checkout init --cone
git sparse-checkout set modules/features/neovim/nvim
git checkout main
```

Then symlink manually:

```bash
ln -s ~/.config/bebop/modules/features/neovim/nvim ~/.config/nvim
```

On a managed NixOS host the symlink is created automatically at rebuild time. The manual step is only needed on unmanaged machines.
