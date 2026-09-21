# Architecture

## Contents

- [Dendritic Pattern](#dendritic-pattern)
- [Auto-Import via import-tree](#auto-import-via-import-tree)
- [Named Profiles](#named-profiles)
- [Module Anatomy](#module-anatomy)
- [NixOS ↔ Home Manager Bridge](#nixos--home-manager-bridge)
- [Darwin ↔ Home Manager Bridge](#darwin--home-manager-bridge)
- [Nixpkgs Channels](#nixpkgs-channels)
- [Variable Schema](#variable-schema)
- [Theming](#theming)
- [Secrets](#secrets)

---

## Dendritic Pattern

This configuration uses the **dendritic nix** pattern: a flake-parts approach where the configuration is organised by concept rather than by layer.

Traditional NixOS configs split things by system layer: `nixos/`, `home/`, `darwin/`. Working on a single feature means touching files across three directories. The dendritic pattern flips this. Each feature directory owns everything it needs: the NixOS-level enablement, the Home Manager config, any bars or daemons. Changes to a feature stay local to that feature's directory.

The key mechanics:

1. Every `.nix` file in `modules/` is auto-imported as a flake-parts module. No manual import lists.
2. Modules expose named profiles rather than configuring systems directly. Profiles are `deferredModule` values, so multiple files can contribute to the same profile name and Nix merges them.
3. Hosts select profiles in their `imports.nix`. Modules never import hosts.

---

## Auto-Import via import-tree

`flake.nix` is intentionally minimal:

```nix
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;}
  (inputs.import-tree ./modules);
```

`import-tree` recursively collects every `.nix` file in `modules/` and merges them as a single flake-parts module. Every file is always imported. Whether a file's configuration takes effect depends entirely on whether the host imports the relevant named profile.

**Critical:** `import-tree` uses git to enumerate files. New `.nix` files must be `git add`ed before they are visible to Nix evaluation.

---

## Named Profiles

`flake-parts.flakeModules.modules` (enabled in `modules/flake/flake-parts.nix`) provides the `flake.modules` option with three namespaces:

| Namespace | Purpose |
|-----------|---------|
| `flake.modules.nixos.<name>` | NixOS system modules |
| `flake.modules.darwin.<name>` | nix-darwin modules |
| `flake.modules.homeManager.<name>` | Home Manager modules |

All three use `deferredModule`, so multiple files can contribute to the same profile name and their contents get merged automatically.

---

## Module Anatomy

Every file in `modules/` is a flake-parts module. Two function forms are used:

```nix
# No flake-parts inputs needed
_: {
  flake.modules.nixos.myfeature = {pkgs, config, ...}: {
    services.myfeature.enable = true;
  };
}

# With flake-parts inputs
{config, inputs, lib, ...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [inputs.something.packages.${pkgs.system}.default];
  };
}
```

The outer function receives flake-parts context. The inner function receives NixOS/HM/Darwin module args.

### Repository layout

```text
modules/
├── flake/      # Flake-parts infrastructure (builders, bridges, var schema, dev shell)
├── hosts/      # Per-machine definitions (nixos/ and darwin/)
├── aspects/    # Foundational system concerns applied broadly
└── features/   # Opt-in capabilities selected per host
```

---

## NixOS ↔ Home Manager Bridge

NixOS profiles don't directly import HM profiles. Each feature that spans both system and user config owns its own wiring from within its feature directory. A NixOS-side file in the feature directory contributes to its NixOS profile and adds `home-manager.users.${username}.imports = [...]` there directly.

`modules/flake/home-manager/nixos.nix` is infrastructure only: it sets up the home-manager NixOS module and activates `hm.base` for every NixOS user.

### Accessing NixOS config from Home Manager

Inside a HM module, `osConfig` provides the NixOS configuration. `config` refers to the HM config only:

```nix
osConfig.sops.secrets.my-secret.path  # NixOS option
osConfig.var.hostname                  # NixOS var option
config.programs.zsh.enable             # HM option
```

---

## Darwin ↔ Home Manager Bridge

`modules/flake/home-manager/darwin.nix` is infrastructure: it sets up the home-manager Darwin module and activates `hm.base`, `hm.gui`, and `hm.shell` for every Darwin user. All Darwin machines in this configuration are GUI machines, so these profiles are applied unconditionally.

Darwin also passes `var` and `inputs` into HM's `extraSpecialArgs` so HM modules can access `var.*` directly.

---

## Nixpkgs Channels

This flake feeds from two nixpkgs channels: `nixpkgs-stable` (nixos-26.05)
and `nixpkgs-unstable` (nixos-unstable). Each host builds from one base
channel, chosen by `role` (servers = stable, clients = unstable). An overlay
exposes both channel sets on every host as `pkgs.stable` / `pkgs.unstable`,
and an assertion locks servers to stable.

Design, per-package escapes, and the update workflow: [Nixpkgs Channels](howto/nixpkgs-channels.md).

---

## Variable Schema

Hosts set typed variables; feature modules read them. Never hardcode hostnames, usernames, or paths that vary between hosts.

```nix
var.network = {                  # LAN topology registry
  subnet = "192.168.68.0/24";
  hosts.ed = "192.168.68.101";   # each host declares its own IPv4
};
```

`var.network` is the LAN address book: `tailscale.nix` advertises the subnet as routes, and `gatus.nix`/`prometheus.nix` reach remote hosts through `hosts.<name>` instead of hardcoded addresses.

---

## Theming

Stylix generates a Base16 color scheme from Catppuccin Mocha, applied system-wide: terminal, window borders, lock screen, GRUB, browser.

Accessing colors in HM modules:
```nix
let inherit (config.lib.stylix) colors; in
# colors.base00 (background), colors.base0D (blue), colors.base0E (mauve), etc.
```

**The wallpaper is not managed by Stylix.** It's set at runtime:
- `swww`/`awww` daemon manages the actual display
- `waypaper` is the GTK picker; it updates `var.wallpaperPath` on every pick via `post_command`
- `var.wallpaperPath` points to `~/.cache/bebop/current-wallpaper`, a symlink updated by waypaper
- the Noctalia lock screen reads `var.wallpaperPath` at runtime for the lock background

`waypaper`'s config is written via `home.activation` rather than `xdg.configFile` so it stays writable at runtime. Waypaper updates the `wallpaper=` line on each pick; a Nix-managed symlink would be read-only and break this.

---

## Secrets

SOPS + age handles secret management. All machines with age keys (spike, ein, jet, ed) can decrypt `modules/aspects/secrets/secrets.yaml`.

Secrets are declared in `modules/aspects/secrets/default.nix` and decrypted at activation time. At runtime they live at `/run/secrets/<name>`.

From a HM module, access the runtime path via:
```nix
osConfig.sops.secrets.my-secret.path
```

For secrets that need to be in a specific file format, use `sops.templates`:
```nix
sops.templates."myapp.json" = {
  content = builtins.toJSON {
    api_key = config.sops.placeholder."my-secret";
  };
  mode = "0444";
};
```

See [Managing Secrets](howto/secrets.md) and [Managing Age Keys](howto/age-keys.md) for practical how-tos.
