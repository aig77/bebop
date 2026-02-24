<p align="center">
  <img src="https://i.redd.it/nalgeor130f31.png" alt="Swordfish" width="600"/>
</p>

---

# bebop

A declarative, multi-platform system configuration built with Nix Flakes. One repo manages NixOS desktops, macOS workstations, and a headless ARM server.

Everything is reproducible. Everything is version-controlled.

![Desktop Screenshot Placeholder](screenshots/desktop.png)
<!-- Replace with an actual screenshot of your Hyprland desktop -->

---

## Hosts

Each host targets a different machine and use case.

### Faye -- Desktop Workstation

> x86_64 NixOS. The daily driver.

Full-featured desktop with Hyprland on Wayland, AMD GPU, gaming, and development tooling.

- Hyprland compositor with custom animations, blur, and rounded corners
- HyprPanel status bar with weather, media controls, system tray
- Fuzzel launcher, Hyprlock lock screen, Wlogout logout menu
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

- Homebrew casks: Brave, Claude, Discord, Docker, Ghostty, LM Studio, Raycast, Steam, Zen
- Home Manager for dotfiles
- Catppuccin theming via Stylix

### Spike -- macOS (Lean)

> aarch64 Darwin (Apple Silicon).

Same foundation as Ein with a trimmer set of apps.

- Core apps: Docker, Discord, Ghostty, LM Studio, Raycast, Zen
- Same shell and development tooling

---

## Features

### Desktop and Window Management

| Component       | Tool                     |
|-----------------|--------------------------|
| Compositor      | Hyprland (Wayland)       |
| Status bar      | HyprPanel                |
| Launcher        | Fuzzel                   |
| Lock screen     | Hyprlock                 |
| Logout menu     | Wlogout                  |
| Idle daemon     | Hypridle                 |
| Notifications   | Dunst                    |

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
  flake.nix                  # Entry point
  hosts/
    nixos/
      faye/                  # Desktop workstation
      ed/                    # Raspberry Pi server
    darwin/
      ein/                   # Mac (full)
      spike/                 # Mac (lean)
  modules/
    common/                  # Shared across all platforms
    nixos/                   # NixOS system modules
    darwin/                  # macOS system modules
    server/                  # Server services (DNS, monitoring)
    home/
      programs/              # User apps (shell, editor, browser, etc.)
      system/                # Desktop environment (Hyprland, bar, lock, etc.)
  themes/                    # Catppuccin Stylix configs
  secrets/                   # SOPS-encrypted secrets
  lib/                       # Helpers (mkSystem, mkSdImage, pre-commit)
```

Each host has a `variables.nix` that sets its identity -- username, hostname, shell, terminal, browser, launcher, and so on. Modules read from these variables so you can swap components without touching every file.

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
