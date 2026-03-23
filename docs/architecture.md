# Architecture

This configuration uses the **dendritic nix** pattern — a flake-parts based approach where every `.nix` file in `modules/` is automatically imported as a flake-parts module via `import-tree`.

## Core Idea

Traditional NixOS configs split things by layer: `nixos/`, `home/`, `darwin/`. This config organises by **concept** instead. A feature like `hyprland/` owns everything it needs — the system-level enablement, the home-manager config, and the bar. This eliminates the friction of hunting across multiple directories when working on one feature.

## Repository Layout

```
bebop/
├── flake.nix                         # Entry point — wires import-tree into flake-parts
├── .sops.yaml                        # SOPS age key configuration (must stay at root)
└── modules/                          # Everything lives here
    ├── flake/                        # Flake-parts infrastructure
    │   ├── flake-parts.nix           # Enables flake.modules.* option
    │   ├── nixosConfigurations.nix   # NixOS system builder
    │   ├── darwinConfigurations.nix  # Darwin system builder
    │   ├── systems.nix               # Supported platforms
    │   ├── formatter.nix             # alejandra formatter
    │   ├── pre-commit.nix            # Pre-commit hooks (statix, deadnix, alejandra)
    │   └── shell.nix                 # Dev shell
    ├── owner/                        # Flake owner metadata (username)
    ├── var/                          # Per-platform variable schemas
    ├── home-manager/                 # Home Manager wiring for NixOS and Darwin
    ├── hosts/                        # Per-machine configuration
    │   ├── nixos/
    │   │   ├── faye/                 # Desktop (x86_64, AMD, Hyprland)
    │   │   └── ed/                   # Server (aarch64, headless)
    │   └── darwin/
    │       ├── ein/                  # MacBook (aarch64-darwin)
    │       └── spike/                # MacBook (aarch64-darwin)
    ├── secrets/                      # SOPS secrets declaration + encrypted file
    ├── theme/                        # Stylix theming (linux + darwin)
    ├── nix/                          # Nix daemon settings
    ├── users/                        # User accounts
    ├── networking/                   # Network configuration
    ├── boot/                         # Bootloader
    ├── audio/                        # PipeWire/PulseAudio
    ├── bluetooth/                    # Bluetooth system service + blueman
    ├── amdgpu/                       # AMD GPU drivers and tools
    ├── nvidia/                       # NVIDIA GPU drivers
    ├── gaming/                       # Steam, Gamemode, Wine
    ├── docker/                       # Docker daemon
    ├── tailscale/                    # Tailscale VPN
    ├── server/                       # Headless server services (DNS)
    ├── hyprland/                     # Hyprland WM (system + HM + bar)
    ├── niri/                         # Niri compositor (system + HM + waybar)
    ├── gnome/                        # GNOME desktop
    ├── hypridle/                     # Idle daemon (shared between WMs)
    ├── hyprlock/                     # Lock screen (shared between WMs)
    ├── waybar/                       # Status bar (used by niri)
    ├── fuzzel/                       # App launcher (shared between WMs)
    ├── rofi/                         # Alternative launcher
    ├── wlogout/                      # Logout menu
    ├── screenshot/                   # Screenshot tooling
    ├── file-manager/                 # Thunar file manager
    ├── darwin/                       # Darwin-specific system settings
    ├── shell/                        # Shell programs (zsh, fish, starship, etc.)
    ├── terminal/                     # Terminal emulators (ghostty, alacritty)
    ├── editor/                       # Text editors (neovim, vim)
    ├── git/                          # Git + lazygit
    ├── browser/                      # Zen browser
    ├── media/                        # OBS, Spotify
    ├── discord/                      # Discord via Nixcord
    ├── notes/                        # Obsidian
    ├── pdf/                          # Zathura PDF viewer
    ├── fetch/                        # Fastfetch system info
    └── ...
```

## How Auto-Import Works

`flake.nix` is intentionally minimal:

```nix
outputs = inputs @ {flake-parts, ...}:
  flake-parts.lib.mkFlake {inherit inputs;}
  (inputs.import-tree ./modules);
```

`import-tree` recursively collects every `.nix` file in `modules/` and merges them as a single flake-parts module. Every file is always imported — there are no enable flags or conditional includes at the file level. Whether a file's config takes effect depends on whether the host imports the relevant named profile.

**Important:** `import-tree` uses git to enumerate files. New files must be `git add`ed before they are visible to Nix evaluation.

## Named Profiles (`flake.modules.*`)

`flake-parts.flakeModules.modules` (enabled in `flake/flake-parts.nix`) provides the `flake.modules` option with three namespaces:

| Namespace | Type | Purpose |
|---|---|---|
| `flake.modules.nixos.<name>` | `deferredModule` | NixOS modules |
| `flake.modules.darwin.<name>` | `deferredModule` | nix-darwin modules |
| `flake.modules.homeManager.<name>` | `deferredModule` | Home Manager modules |

A `deferredModule` merges: multiple files can all set `flake.modules.nixos.base = { ... }` and their contents are automatically combined. No explicit imports needed between files.

### Profile Definitions

#### NixOS profiles

| Profile | Meaning | What's in it |
|---|---|---|
| `base` | Every NixOS machine | nix daemon, users, networking, sops secrets, home-manager wiring |
| `desktop` | Has a screen and a user sitting at it | audio, boot, bluetooth, file-manager, Stylix theme |
| `hyprland` | Uses Hyprland as the WM | Hyprland system enablement, portals |
| `niri` | Uses Niri as the compositor | Niri system enablement, GDM, portals |
| `gnome` | Uses GNOME | GDM, GNOME packages |
| `amdgpu` | AMD graphics card | AMD drivers, ROCm, Vulkan |
| `nvidia` | NVIDIA graphics card | Proprietary NVIDIA drivers |
| `gaming` | Gaming machine | Steam, GameMode, MangoHud, Wine |
| `docker` | Needs containers | Docker daemon, docker group |
| `tailscale` | Connected to Tailnet | Tailscale service, firewall port |
| `server` | Headless server | DNS (Blocky + Unbound), Prometheus |

Profiles are additive — a desktop gaming machine with AMD GPU simply imports `[base desktop hyprland amdgpu gaming]`.

#### Darwin profiles

| Profile | Meaning | What's in it |
|---|---|---|
| `base` | Every Darwin machine | macOS system defaults, homebrew, sops secrets, home-manager wiring, Stylix theme, `var` schema |

Darwin currently has one profile because all Mac machines here share the same base. Host-specific differences (casks, packages) go in the host's own files under `modules/hosts/darwin/<name>/`.

#### Home Manager profiles

| Profile | Meaning | What's in it |
|---|---|---|
| `base` | Every user on every machine | home-manager self-management, username, shell tools (zsh, fish, starship, direnv, fzf, zoxide, tmux), editors (neovim, vim), git, ghostty, alacritty, fastfetch, common CLI packages |
| `gui` | User on a desktop machine | Zen browser, Discord, Spotify, Obsidian, Zathura, Thunar, OBS (Linux only), Rofi |
| `hyprland` | Hyprland user config | Hyprland keybinds/rules, HyprPanel bar |
| `niri` | Niri user config | Niri keybinds/rules, swww wallpaper |
| `gnome` | GNOME user config | GNOME extensions, dconf settings |
| `gaming` | Gaming user tools | Lutris, Bottles, Heroic launcher |
| `fuzzel` | App launcher | Fuzzel config (shared by hyprland + niri) |
| `hyprlock` | Lock screen | Hyprlock config (shared by hyprland + niri) |
| `hypridle` | Idle/suspend | Hypridle config (shared by hyprland + niri) |
| `waybar` | Status bar | Waybar config (used by niri; hyprland uses HyprPanel) |
| `screenshot` | Screenshot scripts | grimblast scripts, Print key bindings |

### How NixOS and HM profiles connect

NixOS profiles don't directly import HM profiles. The bridge is in `home-manager/nixos.nix`, which at flake-parts level reads `config.flake.modules.homeManager.*` and wires them into the NixOS `home-manager.users.<username>.imports` list. This means:

- Importing `nixos.base` → HM user gets `hm.base`
- Importing `nixos.desktop` → HM user gets `hm.gui`
- Importing `nixos.hyprland` → HM user gets `hm.hyprland + hm.fuzzel + hm.hyprlock + hm.hypridle + hm.screenshot`
- Importing `nixos.niri` → HM user gets `hm.niri + hm.waybar + hm.fuzzel + hm.hyprlock + hm.hypridle`

A host that imports `[base desktop hyprland]` therefore ends up with a user that has `[hm.base + hm.gui + hm.hyprland + hm.fuzzel + hm.hyprlock + hm.hypridle + hm.screenshot]` — all without the host file listing any HM profiles directly.

### Full profile stack for faye

```
nixos.base        → nix, users, networking, secrets, home-manager
  └─ hm.base      → shell tools, editors, git, terminal, CLI packages

nixos.desktop     → audio, boot, bluetooth, file-manager, theme
  └─ hm.gui       → browser, discord, spotify, apps

nixos.hyprland    → Hyprland system, portals
  └─ hm.hyprland  → keybinds, window rules, HyprPanel bar
  └─ hm.fuzzel    → launcher
  └─ hm.hyprlock  → lock screen
  └─ hm.hypridle  → idle/suspend
  └─ hm.screenshot → screenshot scripts

nixos.amdgpu      → AMD drivers, Vulkan, ROCm
nixos.gaming      → Steam, GameMode, Wine
  └─ hm.gaming    → Lutris, Bottles, Heroic

nixos.docker      → Docker daemon
nixos.tailscale   → Tailscale VPN
```

## How a Host Gets Built

A host like `faye` works through several layers of auto-imported files that all contribute to `configurations.nixos.faye.module`:

```
modules/hosts/nixos/faye/imports.nix    → selects which named profiles to include
modules/hosts/nixos/faye/variables.nix  → sets var.* values (hostname, shell, etc.)
modules/hosts/nixos/faye/hardware.nix   → kernel modules, CPU microcode, hostPlatform
modules/hosts/nixos/faye/disko.nix      → disk layout for fresh installs
modules/hosts/nixos/faye/home.nix       → faye-specific home-manager packages
modules/hosts/nixos/faye/state-version.nix → system.stateVersion
```

All of these are separate flake-parts modules that each contribute to the same `configurations.nixos.faye.module` deferredModule. Nix merges them automatically.

`nixosConfigurations.nix` then maps every `configurations.nixos.<name>` entry into a `flake.nixosConfigurations.<name>` output, passing the merged module through `nixpkgs.lib.nixosSystem`.
