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

### NixOS profiles

| Profile | Applied to | Contents |
|---------|-----------|----------|
| `base` | Every NixOS machine | nix daemon, users, networking, sops secrets, home-manager wiring |
| `desktop` | Machines with a display | audio, boot, bluetooth, fileManager, Stylix theme |
| `hyprland` | Hyprland compositor base | Hyprland system enablement, GDM, portals |
| `hyprland-quickshell` | Hyprland + Quickshell bar | `nixos.hyprland` + Quickshell as bar/launcher |
| `hyprland-hyprpanel` | Hyprland + HyprPanel bar | `nixos.hyprland` + HyprPanel as bar |
| `hyprland-custom` | Hyprland + Waybar | `nixos.hyprland` + Waybar + SwayNC |
| `niri` | Niri compositor | Niri system enablement, GDM, portals |
| `gnome` | GNOME desktop | GDM, GNOME packages |
| `amdgpu` | AMD GPU machines | AMD drivers, ROCm, Vulkan |
| `nvidia` | NVIDIA GPU machines | Proprietary NVIDIA drivers |
| `gaming` | Gaming machines | Steam, GameMode, MangoHud, Wine |
| `docker` | Needs containers | Docker daemon, docker group |
| `tailscale` | Connected to Tailnet | Tailscale service, firewall port |
| `server` | Headless servers | DNS (Blocky + Unbound), Prometheus |
| `volt` | Faye only | Pins Volt 476 audio interface to stereo profile |

### Darwin profiles

| Profile | Contents |
|---------|----------|
| `base` | macOS system defaults, homebrew, sops secrets, home-manager wiring, Stylix theme, `var` schema |
| `eyecandy` | CLI eye candy (fastfetch, cava, aliases) |

### Home Manager profiles

| Profile | Contents |
|---------|----------|
| `base` | Shell tools (zsh/fish guarded by `var.shell`, starship, direnv, fzf, zoxide, tmux), editors (neovim, vim), git, terminal (ghostty/alacritty guarded by `var.terminal`), btop, common CLI packages |
| `gui` | Zen browser, Discord, Spotify, Obsidian, Zathura, file manager, OBS (Linux only) |
| `hyprland` | Hyprland keybinds/rules/animations, polkit agent |
| `quickshell` | Quickshell bar/launcher + hyprlock + hypridle + fuzzel + wallpaper manager |
| `hyprpanelShell` | HyprPanel bar + hyprlock + hypridle + fuzzel |
| `customDesktopShell` | Waybar + SwayNC + fuzzel + hyprlock + hypridle + wallpaper manager |
| `niri` | Niri keybinds/rules/wallpaper |
| `gnome` | GNOME extensions, dconf settings |
| `gaming` | MangoHud, Heroic, Bottles, ProtonPlus |
| `eyecandyBase` | fastfetch + krabby fetch alias + eye candy packages |
| `eyecandyNixos` | `eyecandyBase` + cava audio visualizer + tty-clock |
| `fastfetch` | fastfetch config |
| `krabby` | krabby + fastfetch shell aliases and greeting |
| `eyecandyPackages` | cmatrix, pipes-rs, cbonsai, asciiquarium, etc. |
| `cava` | cava audio visualizer with Stylix gradient |
| `fuzzel` | App launcher config |
| `hyprlock` | Lock screen config |
| `hypridle` | Idle/suspend daemon |
| `waybar` | Status bar config |
| `screenshot` | grimblast scripts, Print key bindings |
| `wallpaperManager` | waypaper + awww (conditional on `var.wallpaperEngine`) |
| `btopAmd` | btop with ROCm GPU support |
| `btopNvidia` | btop with NVML GPU support |

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

```
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

| NixOS profile | HM profiles activated | Wiring lives in |
|---------------|-----------------------|-----------------|
| `base` | `hm.base` | `flake/home-manager/nixos.nix` |
| `desktop` | `hm.shell`, `hm.gui`, `hm.eyecandyNixos` | `aspects/desktop/home.nix` |
| `hyprland-quickshell` | `hm.hyprland`, `hm.quickshell`, `hm.screenshot` | `features/hyprland/quickshell.nix` |
| `hyprland-hyprpanel` | `hm.hyprland`, `hm.hyprpanelShell`, `hm.screenshot` | `features/hyprland/hyprpanel.nix` |
| `hyprland-custom` | `hm.hyprland`, `hm.customDesktopShell`, `hm.screenshot` | `features/hyprland/custom.nix` |
| `niri` | `hm.niri`, `hm.customDesktopShell` | `features/niri/nixos.nix` |
| `gnome` | `hm.gnome` | `features/gnome/nixos.nix` |
| `gaming` | `hm.gaming` | `features/gaming/nixos.nix` |
| `amdgpu` | `hm.btopAmd` | `features/amdgpu/default.nix` |
| `nvidia` | `hm.btopNvidia` | `features/nvidia/default.nix` |

### Full profile stack for faye

```
nixos.base              -> nix, users, networking, secrets
  hm.base               -> (empty, harmless no-op)

nixos.desktop           -> audio, boot, bluetooth, theme
  hm.shell              -> shell (var.shell), terminals (var.terminal), editors, git, CLI packages
  hm.gui                -> browser, discord, spotify, apps
  hm.eyecandyNixos      -> fastfetch, krabby, cava, eye candy packages

nixos.hyprland-quickshell -> Hyprland system, GDM, portals
  hm.hyprland           -> keybinds, window rules, animations
  hm.quickshell         -> bar/launcher + hyprlock + hypridle + fuzzel + wallpaper
  hm.screenshot         -> screenshot scripts

nixos.amdgpu            -> AMD drivers, Vulkan, ROCm
  hm.btopAmd            -> btop with GPU stats

nixos.gaming            -> Steam, GameMode, Wine
  hm.gaming             -> MangoHud, Heroic, Bottles

nixos.docker            -> Docker daemon
nixos.tailscale         -> Tailscale VPN
nixos.volt              -> Volt 476 audio profile pin
```

### Accessing NixOS config from Home Manager

Inside a HM module, `osConfig` provides the NixOS configuration. `config` refers to the HM config only:

```nix
osConfig.sops.secrets.my-secret.path  # NixOS option
osConfig.var.hostname                  # NixOS var option
config.programs.zsh.enable             # HM option
```

---

## Darwin ↔ Home Manager Bridge

`modules/flake/home-manager/darwin.nix` is infrastructure: it sets up the home-manager Darwin module and activates `hm.base`, `hm.gui`, and `hm.shell` for every Darwin user. All Mac machines get these unconditionally since there are no headless Darwin configs here.

Darwin also passes `var` and `inputs` into HM's `extraSpecialArgs` so HM modules can access `var.*` directly.

The optional `darwin.eyecandy` profile wires `hm.eyecandyBase`; its wiring lives in `features/eyecandy/darwin.nix`.

---

## Variable Schema

Hosts set typed variables; feature modules read them. Never hardcode hostnames, usernames, or paths that vary between hosts.

### NixOS (`modules/flake/var/default.nix`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `var.username` | str | | System username |
| `var.hostname` | str | | Machine hostname |
| `var.shell` | enum | | `"zsh"` or `"fish"` |
| `var.terminal` | str | `"ghostty"` | Default terminal emulator |
| `var.browser` | str | `"zen"` | Default browser |
| `var.location` | str | `""` | City name for weather widgets |
| `var.launcher` | str | `"fuzzel"` | App launcher (`"fuzzel"`, `"rofi"`, `"quickshell"`) |
| `var.fileManager` | str | `"nautilus"` | File manager |
| `var.lock` | str | `"hyprlock"` | Lock screen command |
| `var.logout` | str | `"wlogout"` | Logout menu command |
| `var.wallpaperEngine` | str | `"swww"` | Wallpaper backend |
| `var.wallpaperPath` | str | `"$HOME/.cache/bebop/current-wallpaper"` | Runtime symlink to current wallpaper |

### Darwin (`modules/flake/var/darwin.nix`)

Darwin has a smaller set: `username`, `hostname`, `shell`, `terminal`, `browser`.

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
- `hyprlock` reads `var.wallpaperPath` at eval time for the lock screen background

`waypaper`'s config is written via `home.activation` rather than `xdg.configFile` so it stays writable at runtime. Waypaper updates the `wallpaper=` line on each pick; a Nix-managed symlink would be read-only and break this.

---

## Secrets

SOPS + age handles secret management. All four machines' age keys can decrypt `modules/aspects/secrets/secrets.yaml`.

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
