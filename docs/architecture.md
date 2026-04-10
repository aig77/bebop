# Architecture

## Contents

- [Dendritic Pattern](#dendritic-pattern)
- [Auto-Import via import-tree](#auto-import-via-import-tree)
- [Named Profiles](#named-profiles)
- [Module Anatomy](#module-anatomy)
- [NixOS ↔ Home Manager Bridge](#nixos--home-manager-bridge)
- [Darwin ↔ Home Manager Bridge](#darwin--home-manager-bridge)
- [Variable Schema](#variable-schema)
- [Theming](#theming)
- [Secrets](#secrets)

---

## Dendritic Pattern

This configuration uses the **dendritic nix** pattern — a flake-parts approach where the configuration is organised by **concept** rather than by layer.

Traditional NixOS configs split things by system layer: `nixos/`, `home/`, `darwin/`. This creates friction: when working on a feature like Hyprland, you have to touch files in three separate directories. The dendritic pattern inverts this. Each feature directory owns everything it needs — the NixOS-level enablement, the Home Manager config, and any bars or daemons. Changes to a feature stay local to that feature's directory.

The key mechanisms:

1. Every `.nix` file in `modules/` is auto-imported as a flake-parts module (no manual import lists).
2. Modules **expose** named profiles rather than being applied directly. Profiles are `deferredModule` values — multiple files can contribute to the same profile name and Nix merges them.
3. Hosts **select** profiles in their `imports.nix`. Modules never import hosts.

---

## Auto-Import via import-tree

`flake.nix` is intentionally minimal:

```nix
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;}
  (inputs.import-tree ./modules);
```

`import-tree` recursively collects every `.nix` file in `modules/` and merges them as a single flake-parts module. Every file is always imported — there are no enable flags or conditional includes at the file level. Whether a file's configuration takes effect depends entirely on whether the host imports the relevant named profile.

**Critical:** `import-tree` uses git to enumerate files. New `.nix` files must be `git add`ed before they are visible to Nix evaluation.

---

## Named Profiles

`flake-parts.flakeModules.modules` (enabled in `modules/flake/flake-parts.nix`) provides the `flake.modules` option with three namespaces:

| Namespace | Purpose |
|-----------|---------|
| `flake.modules.nixos.<name>` | NixOS system modules |
| `flake.modules.darwin.<name>` | nix-darwin modules |
| `flake.modules.homeManager.<name>` | Home Manager modules |

All three use `deferredModule`, which means multiple files can all contribute to the same profile name and their contents are automatically merged — no explicit imports between files needed.

### NixOS profiles

| Profile | Applied to | Contents |
|---------|-----------|----------|
| `base` | Every NixOS machine | nix daemon, users, networking, sops secrets, home-manager wiring |
| `desktop` | Machines with a display | audio, boot, bluetooth, file-manager, Stylix theme |
| `hyprland` | Hyprland compositor | Hyprland system enablement, portals |
| `hyprland-quickshell` | Hyprland + Quickshell bar | Hyprland + Quickshell launcher/bar |
| `niri` | Niri compositor | Niri system enablement, GDM, portals |
| `gnome` | GNOME desktop | GDM, GNOME packages |
| `amdgpu` | AMD GPU machines | AMD drivers, ROCm, Vulkan |
| `nvidia` | NVIDIA GPU machines | Proprietary NVIDIA drivers |
| `gaming` | Gaming machines | Steam, GameMode, MangoHud, Wine |
| `docker` | Needs containers | Docker daemon, docker group |
| `tailscale` | Connected to Tailnet | Tailscale service, firewall port |
| `server` | Headless servers | DNS (Blocky + Unbound), Prometheus |
| `volt` | Faye-specific | Pins Volt 476 audio interface to stereo profile |

### Darwin profiles

| Profile | Contents |
|---------|----------|
| `base` | macOS system defaults, homebrew, sops secrets, home-manager wiring, Stylix theme, `var` schema |
| `eyecandy` | CLI eye candy (fastfetch, cava, aliases) |

### Home Manager profiles

| Profile | Contents |
|---------|----------|
| `base` | Shell tools (zsh/fish, starship, direnv, fzf, zoxide, tmux), editors (neovim, vim), git, terminal, fastfetch, common CLI packages |
| `gui` | Zen browser, Discord, Spotify, Obsidian, Zathura, file manager, OBS (Linux only) |
| `hyprland` | Hyprland keybinds/rules, HyprPanel bar |
| `niri` | Niri keybinds/rules, swww wallpaper |
| `gnome` | GNOME extensions, dconf settings |
| `gaming` | Lutris, Bottles, Heroic launcher |
| `fuzzel` | App launcher config |
| `hyprlock` | Lock screen config |
| `hypridle` | Idle/suspend daemon |
| `waybar` | Status bar config (used by niri; hyprland uses HyprPanel) |
| `screenshot` | grimblast scripts, Print key bindings |

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

# With flake-parts inputs (lib, config, inputs, etc.)
{config, inputs, lib, ...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [inputs.something.packages.${pkgs.system}.default];
  };
}
```

The outer function receives flake-parts context. The inner function (the profile value) receives NixOS/HM/Darwin module args.

### Repository layout

```
modules/
├── flake/      # Flake-parts infrastructure (builders, bridges, var schema, dev shell)
├── hosts/      # Per-machine definitions (nixos/ and darwin/)
├── aspects/    # Foundational system concerns applied broadly
└── features/   # Opt-in capabilities selected per host
```

---

## NixOS ↔ Home Manager Bridge

NixOS profiles don't directly import HM profiles. The bridge is `modules/flake/home-manager/nixos.nix`, which at flake-parts level reads `config.flake.modules.homeManager.*` and wires them into `home-manager.users.<username>.imports`.

This means importing a NixOS profile automatically activates the corresponding HM profiles:

| NixOS profile imported | HM profiles activated |
|------------------------|-----------------------|
| `base` | `hm.base` |
| `desktop` | `hm.gui` |
| `hyprland` | `hm.hyprland`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle`, `hm.screenshot` |
| `hyprland-quickshell` | same as `hyprland` + quickshell bar |
| `niri` | `hm.niri`, `hm.waybar`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle` |
| `gnome` | `hm.gnome` |
| `gaming` | `hm.gaming` |

A host that imports `[base desktop hyprland amdgpu gaming]` automatically ends up with a user that has `[hm.base + hm.gui + hm.hyprland + hm.fuzzel + hm.hyprlock + hm.hypridle + hm.screenshot + hm.gaming]` — the host file never lists any HM profiles directly.

### Full profile stack for faye

```
nixos.base              → nix, users, networking, secrets
  └─ hm.base            → shell tools, editors, git, terminal, CLI packages

nixos.desktop           → audio, boot, bluetooth, theme
  └─ hm.gui             → browser, discord, spotify, apps

nixos.hyprland-quickshell → Hyprland system, portals, quickshell
  └─ hm.hyprland        → keybinds, window rules, HyprPanel bar
  └─ hm.fuzzel          → app launcher
  └─ hm.hyprlock        → lock screen
  └─ hm.hypridle        → idle/suspend
  └─ hm.screenshot      → screenshot scripts

nixos.amdgpu            → AMD drivers, Vulkan, ROCm
nixos.gaming            → Steam, GameMode, Wine
  └─ hm.gaming          → Lutris, Bottles, Heroic

nixos.docker            → Docker daemon
nixos.tailscale         → Tailscale VPN
nixos.volt              → Volt 476 audio profile pin
```

### Accessing NixOS config from Home Manager

Inside a HM module, `osConfig` provides the NixOS configuration. Regular `config` refers to the HM config only:

```nix
# In a HM module:
osConfig.sops.secrets.my-secret.path  # NixOS option
osConfig.var.hostname                  # NixOS var option
config.programs.zsh.enable             # HM option
```

---

## Darwin ↔ Home Manager Bridge

`modules/flake/home-manager/darwin.nix` wires `hm.base` and `hm.gui` into all Darwin configurations. Darwin machines always get both profiles since there are no headless Darwin configurations here.

Darwin also passes `var` and `inputs` into HM's `extraSpecialArgs` so HM modules can access `var.*` directly.

---

## Variable Schema

Hosts set typed variables; feature modules read them rather than hardcoding values. This is the interface between host config and feature modules.

### NixOS variables (`modules/flake/var/default.nix`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `var.username` | str | — | System username |
| `var.hostname` | str | — | Machine hostname |
| `var.shell` | enum | — | `"zsh"` or `"fish"` |
| `var.terminal` | str | `"ghostty"` | Default terminal emulator |
| `var.browser` | str | `"zen"` | Default browser |
| `var.location` | str | `""` | City name for weather widgets |
| `var.launcher` | str | `"fuzzel"` | App launcher (`"fuzzel"`, `"rofi"`, `"quickshell"`) |
| `var.fileManager` | str | `"nautilus"` | File manager |
| `var.lock` | str | `"hyprlock"` | Lock screen command |
| `var.logout` | str | `"wlogout"` | Logout menu command |
| `var.wallpaperEngine` | str | `"swww"` | Wallpaper backend |
| `var.wallpaperPath` | str | `"$HOME/.cache/bebop/current-wallpaper"` | Runtime symlink to current wallpaper |

### Darwin variables (`modules/flake/var/darwin.nix`)

Darwin has a smaller set: `username`, `hostname`, `shell`, `terminal`, `browser`.

---

## Theming

Stylix generates a Base16 color scheme from Catppuccin Mocha. It is applied system-wide — terminal, window borders, lock screen, GRUB, browser.

Accessing colors in HM modules:
```nix
let inherit (config.lib.stylix) colors; in
# colors.base00 (background), colors.base0D (blue), colors.base0E (mauve), etc.
```

**The wallpaper is not managed by Stylix.** It is set at runtime:
- `swww`/`awww` daemon manages the display
- `waypaper` is the GTK picker; it updates `var.wallpaperPath` on every selection via `post_command`
- `var.wallpaperPath` points to `~/.cache/bebop/current-wallpaper` — a symlink updated by waypaper
- `hyprlock` reads `var.wallpaperPath` at eval time for the lock screen background

`waypaper`'s config file is written via `home.activation` rather than `xdg.configFile` so it remains writable at runtime (waypaper updates the `wallpaper=` line on each pick; a Nix-managed symlink would be read-only and break this).

---

## Secrets

SOPS + age handles secret management. All four machines' age keys can decrypt the single `modules/aspects/secrets/secrets.yaml` file.

Secrets are declared in `modules/aspects/secrets/default.nix` and decrypted at activation time. At runtime they are available at `/run/secrets/<name>`.

From a HM module, access the runtime path via:
```nix
osConfig.sops.secrets.my-secret.path
```

For secrets that need to be in a config file format, use `sops.templates`:
```nix
sops.templates."myapp.json" = {
  content = builtins.toJSON {
    api_key = config.sops.placeholder."my-secret";
  };
  mode = "0444";
};
```

See [Managing Secrets](howto/secrets.md) and [Managing Age Keys](howto/age-keys.md) for practical how-tos.
