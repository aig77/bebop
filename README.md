<p align="center">
  <img src="https://i.redd.it/nalgeor130f31.png" alt="Swordfish" width="600"/>
</p>

---

# bebop

A declarative, multi-platform system configuration built with Nix Flakes and flake-parts. One repo manages NixOS desktops, macOS workstations, and a headless ARM server.

Everything is a composable flake-parts module. Everything is reproducible. Everything is version-controlled.

![Desktop Screenshot Placeholder](screenshots/desktop.png)
<!-- Replace with an actual screenshot of your Hyprland desktop -->

---

## Hosts

Each host targets a different machine and use case.

### Faye -- Desktop Workstation

> x86_64 NixOS. The daily driver.

Full-featured desktop with Hyprland on Wayland, AMD GPU, gaming, and development tooling.

- Hyprland compositor with custom animations, blur, and rounded corners
- Waybar status bar (custom pill layout) with media controls, workspaces, volume, notifications
- SwayNC notification center, Fuzzel launcher, Hyprlock lock screen, Wlogout logout menu
- Gaming: Steam with Proton, Heroic, Bottles, GameMode, MangoHud
- Ghostty terminal, Zen browser, Neovim, Tmux
- Spotify (Spicetify), Discord (Nixcord), Obsidian, OBS
- Declarative disk partitioning via Disko
- Catppuccin Mocha everywhere

![Faye Screenshot Placeholder](screenshots/faye-desktop.png)
<!-- Replace with a screenshot of the faye desktop -->

### Ed -- Raspberry Pi Server

> aarch64 NixOS. Headless. Quiet. Always running.

Handles network services from a Raspberry Pi. No GUI, just DNS and monitoring.

- Blocky DNS with ad blocking (StevenBlack hosts list)
- Unbound recursive resolver with DNSSEC
- Prometheus metrics collection
- Grafana dashboards for monitoring
- Auto-expanding root partition, watchdog for auto-reboot
- Builds as a flashable SD card image

### Ein -- macOS (Full)

> aarch64 Darwin (Apple Silicon).

Managed through nix-darwin and Homebrew. Same shell, same tools, same theme -- just on Apple hardware.

- Homebrew casks: Brave, Claude, Discord, Docker Desktop, Ghostty, HTTPie Desktop, LM Studio, Raycast, Steam, Tailscale, WhatsApp
- Home Manager for dotfiles
- Catppuccin theming via Stylix

### Spike -- macOS (Lean)

> aarch64 Darwin (Apple Silicon).

Same foundation as Ein with a trimmer set of apps.

- Core apps: Docker, Discord, Ghostty, LM Studio, Proton Mail Bridge, Raycast, Tailscale, Zen
- Same shell and development tooling

---

## Features

### Desktop and Window Management

| Component       | Tool                     |
|-----------------|--------------------------|
| Compositor      | Hyprland (Wayland)       |
| Status bar      | Waybar (custom pill)     |
| Launcher        | Fuzzel                   |
| Lock screen     | Hyprlock                 |
| Logout menu     | Wlogout                  |
| Idle daemon     | Hypridle                 |
| Notifications   | SwayNC                   |

![Hyprland Screenshot Placeholder](screenshots/hyprland.png)
<!-- Replace with a screenshot showing the tiling layout, bar, and launcher -->

### Shell and Terminal

| Component       | Tool                     |
|-----------------|--------------------------|
| Terminal        | Ghostty                  |
| Shell           | ZSH (Fish available)     |
| Prompt          | Starship                 |
| Multiplexer     | Tmux                     |
| Fuzzy finder    | FZF                      |
| Directory jump  | Zoxide                   |
| Env management  | Direnv                   |

ZSH is set up with vi mode, syntax highlighting, autosuggestions, and fzf-tab completions. The shell greeting uses Krabby (Pokemon ASCII art) paired with Fastfetch.

![Terminal Screenshot Placeholder](screenshots/terminal.png)
<!-- Replace with a screenshot of the terminal showing the fetch + prompt -->

### Development

The development workflow leans on Nix flakes, devenv, and direnv. Each project gets its own `flake.nix` (or `devenv.nix`) that defines the shell environment -- dependencies, toolchains, environment variables, services. Direnv picks these up automatically when you `cd` into a project directory, so you never install things globally and every collaborator gets the same setup.

On top of that:

- Neovim as the primary editor
- Git + Lazygit for version control
- Rust, Python (uv), and Go toolchains available
- Claude Code and OpenCode CLI agents
- GitHub CLI
- Nix tooling: Alejandra, deadnix, statix, nil, nixd

### Applications

| Category        | Apps                                    |
|-----------------|-----------------------------------------|
| Browser         | Zen (privacy-hardened, Brave search)    |
| Notes           | Obsidian                                |
| Music           | Spotify (Spicetify)                     |
| Chat            | Discord (Nixcord)                       |
| Passwords       | Bitwarden                               |
| PDF viewer      | Zathura                                 |
| Video           | VLC                                     |
| Streaming       | OBS Studio                              |
| Local AI        | LM Studio                               |

### Gaming (Faye only)

Steam with Proton, Heroic Launcher for GOG/Epic, Bottles for Windows apps, GameMode for performance, MangoHud for overlays. Games get their own workspace.

### Theming

Everything uses **Catppuccin Mocha**. Stylix handles the Base16 color scheme across the entire system -- terminal, window borders, lock screen, browser, GRUB, the lot.

| Element         | Choice                   |
|-----------------|--------------------------|
| Color scheme    | Catppuccin Mocha         |
| Mono font       | JetBrains Mono Nerd Font |
| Sans font       | DejaVu Sans              |
| Icons           | Papirus-Dark             |
| Cursors         | Catppuccin Mocha Light   |
| GRUB theme      | Vimix                    |
| Boot splash     | Plymouth (Lone theme)    |

![Theme Screenshot Placeholder](screenshots/theme.png)
<!-- Replace with a screenshot showing the color scheme / theming -->

### Monitoring (Ed only)

Blocky handles DNS-level ad blocking with Cloudflare DoH upstream. Unbound provides a local recursive resolver. Prometheus scrapes metrics from the node exporter and Blocky, and Grafana puts it all on dashboards.

### Secrets

Managed with SOPS and age encryption. Git email, Grafana credentials, and API keys are all encrypted in the repo and decrypted at build time.

---

## Repo Structure

```
bebop/
├── flake.nix                # Entry point — wires import-tree into flake-parts
└── modules/                 # Everything lives here; all files auto-imported
    ├── flake/               # Flake-parts infrastructure (builders, formatter, shell)
    ├── hosts/               # Per-machine configuration
    │   ├── nixos/
    │   │   ├── faye/        # Desktop workstation (x86_64, AMD, Hyprland)
    │   │   └── ed/          # Raspberry Pi server (aarch64, headless)
    │   └── darwin/
    │       ├── ein/         # MacBook (aarch64-darwin, full)
    │       └── spike/       # MacBook (aarch64-darwin, lean)
    ├── secrets/             # SOPS secrets declaration + encrypted file
    ├── theme/               # Stylix theming (linux + darwin)
    ├── owner/               # Flake owner metadata
    ├── var/                 # Per-platform variable schemas
    ├── home-manager/        # Home Manager wiring
    ├── hyprland/            # Hyprland WM (system + HM config)
    ├── customDesktopShell/  # Waybar, SwayNC, Fuzzel, Hyprlock, Hypridle
    ├── niri/                # Niri compositor (system + HM + waybar)
    ├── gaming/              # Steam, GameMode, Wine, launchers
    ├── shell/               # ZSH, fish, starship, tmux, fzf, zoxide, direnv
    ├── editor/              # Neovim, vim
    ├── browser/             # Zen browser
    ├── terminal/            # Ghostty, alacritty
    └── ...                  # amdgpu, audio, bluetooth, docker, tailscale, etc.
```

Every `.nix` file in `modules/` is automatically imported via `import-tree` — there's no manual import list to maintain. Hosts select behaviour by composing named profiles (`configurations.nixos.faye.module = { imports = [base desktop hyprland amdgpu gaming ...]; }`). Each profile is a `deferredModule` that multiple files contribute to, so features stay co-located by concept rather than split across `nixos/`, `home/`, and `darwin/` directories.

Each host directory contains `imports.nix` (profile selection), `variables.nix` (hostname, shell, etc.), and any machine-specific files. See [`docs/architecture.md`](docs/architecture.md) for the full picture.

---

## Deploying

**NixOS:**
```bash
nixos-rebuild switch --flake .#faye
nixos-rebuild switch --flake .#ed
```

**macOS:**
```bash
darwin-rebuild switch --flake .#ein
darwin-rebuild switch --flake .#spike
```

**Fresh install (remote, via nixos-anywhere):**
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#faye \
  --disk-device /dev/nvme0n1 \
  root@<target-ip>
```

**Build an SD image for Ed:**
```bash
nix build .#images.ed
```

**Development shell:**
```bash
nix develop
```

Pre-commit hooks (Alejandra, deadnix, statix) run automatically on every commit to keep things clean.

---

<p align="center"><i>See You Space Cowboy...</i></p>
