# Features

## Contents

- [What Are Features](#what-are-features)
- [Desktop Environments](#desktop-environments)
- [Desktop Components](#desktop-components)
- [Applications](#applications)
- [System Services](#system-services)
- [Darwin-Specific](#darwin-specific)

---

## What Are Features

Features are opt-in capabilities that a host explicitly selects in its `imports.nix`. They represent things a machine chooses to have: a desktop environment, a set of applications, a system service.

Features live in `modules/features/` and contribute to named profiles that hosts import. A feature directory can contain multiple files contributing to different profiles (e.g., `hyprland/nixos.nix` for `nixos.hyprland` and `hyprland/home.nix` for `homeManager.hyprland`).

See [Aspects](aspects.md) for foundational system concerns.

---

## Desktop Environments

Full compositor/WM setups. Each owns its system-level enablement and HM configuration.

| Feature | Path | Profiles | Description |
|---------|------|----------|-------------|
| Hyprland (base) | `features/hyprland/` | `nixos.hyprland`, `hm.hyprland` | System enablement + portals (nixos.nix), keybinds/animations/window rules (home.nix). Uses `var.*` for terminal, browser, launcher, lock, logout. Not used directly; hosts import one of the variant profiles below |
| Hyprland + Quickshell | `features/hyprland/quickshell.nix` | `nixos.hyprland-quickshell` | Hyprland with Quickshell as bar/launcher. Activates `hm.hyprland`, `hm.quickshell`, `hm.screenshot`. Sets `var.launcher = "quickshell"` |
| Hyprland + HyprPanel | `features/hyprland/hyprpanel.nix` | `nixos.hyprland-hyprpanel` | Hyprland with HyprPanel bar. Activates `hm.hyprland`, `hm.hyprpanelShell`, `hm.screenshot` |
| Hyprland + Custom | `features/hyprland/custom.nix` | `nixos.hyprland-custom` | Hyprland with Waybar + SwayNC. Activates `hm.hyprland`, `hm.customDesktopShell`, `hm.screenshot` |
| Niri | `features/niri/` | `nixos.niri`, `hm.niri` | GDM + Niri session (nixos.nix), keybinds/rules/wallpaper (home.nix), niri-specific Waybar (waybar.nix) |
| GNOME | `features/gnome/` | `nixos.gnome`, `hm.gnome` | GDM + GNOME packages (nixos.nix), shell extensions via dconf (extensions.nix) |

---

## Desktop Components

Standalone components composable across multiple WM setups.

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| HyprPanel | `features/hyprpanel/` | `hm.hyprpanelShell` | Bar config; layout varies by hostname. Weather widget reads API key via `osConfig.sops.templates` |
| Waybar | `features/waybar/` | `hm.waybar` | Status bar for niri and Hyprland custom shell |
| SwayNC | `features/notifications/` | `hm.customDesktopShell` | Notification center/daemon, bundled in `customDesktopShell` |
| Hyprlock | `features/hyprlock/` | `hm.hyprlock` | Lock screen with Stylix-themed background from `var.wallpaperPath`, blur |
| Hypridle | `features/hypridle/` | `hm.hypridle` | Idle daemon: dim at 4min, lock at 5min, suspend at 10min |
| Fuzzel | `features/fuzzel/` | `hm.fuzzel` | App launcher shared between Hyprland and niri |
| Quickshell | `features/quickshell/` | `hm.quickshell` | Quickshell bar/launcher widget framework |
| Wallpaper | `features/wallpaper/` | `hm.wallpaperManager` | Three-file split: `swww.nix` (daemon + restore service), `waypaper.nix` (GTK picker + `post_command` symlink), `default.nix` (composite profile). Config written via `home.activation` so it stays writable at runtime |
| Screenshot | `features/screenshot/` | `hm.screenshot` | grimblast scripts bound to Print keys |
| File manager | `features/fileManager/` | `nixos.desktop` | Thunar with archive and media tag plugins |
| Eyecandy | `features/eyecandy/` | `darwin.eyecandy`, `hm.eyecandyBase`, `hm.eyecandyNixos` | Sub-modules: `hm.fastfetch` (fastfetch config), `hm.krabby` (krabby + fetch alias), `hm.cava` (audio visualizer), `hm.eyecandyPackages` (cmatrix, pipes-rs, cbonsai, etc.). Composite: `hm.eyecandyBase` = fastfetch + krabby + packages (Darwin); `hm.eyecandyNixos` = eyecandyBase + cava + tty-clock (NixOS desktop) |

---

## Applications

All Home Manager modules. Most contribute to `hm.shell` or `hm.gui`.

### Shell and Terminal

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| ZSH | `features/shell/zsh.nix` | `hm.shell` | Completions, autosuggestions, syntax highlighting, vi mode, fzf-tab. Active when `var.shell == "zsh"` |
| Fish | `features/shell/fish.nix` | `hm.shell` | Fish shell config and abbreviations. Active when `var.shell == "fish"` |
| Starship | `features/shell/starship.nix` | `hm.shell` | Cross-shell prompt |
| Direnv | `features/shell/direnv.nix` | `hm.shell` | Automatic dev shell activation with nix-direnv |
| FZF | `features/shell/fzf.nix` | `hm.shell` | Fuzzy finder with shell integration |
| Zoxide | `features/shell/zoxide.nix` | `hm.shell` | Smart `cd` replacement |
| Tmux | `features/shell/tmux.nix` | `hm.shell` | Tmux with Catppuccin theme |
| CLI packages | `features/shell/packages.nix` | `hm.shell` | ripgrep, fd, bat, eza, jq, htop, wget, curl, unzip, etc. |
| Neovim | `features/editor/neovim.nix` | `hm.shell` | LSP, treesitter, mini.nvim, mason |
| Vim | `features/editor/vim.nix` | `hm.shell` | Minimal vim config as fallback |
| Git | `features/git/git.nix` | `hm.shell` | Username from `var.username`, email from sops secret at runtime |
| Lazygit | `features/git/lazygit.nix` | `hm.shell` | Lazygit TUI with Catppuccin theme |

### GUI Applications

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| Ghostty | `features/terminal/ghostty.nix` | `hm.gui` | Ghostty terminal (Stylix handles colors). Active when `var.terminal == "ghostty"` |
| Alacritty | `features/terminal/alacritty.nix` | `hm.gui` | Alacritty as fallback terminal. Active when `var.terminal == "alacritty"` |
| Zen browser | `features/browser/zen.nix` | `hm.gui` | Privacy-hardened Firefox fork: containers, Brave search, uBlock Origin, Bitwarden, etc. |
| Discord | `features/discord/nixcord.nix` | `hm.gui` | Discord via Nixcord (Vencord-patched), Stylix CSS theme |
| Spotify | `features/media/spotify.nix` | `hm.gui` | Spotify via spicetify-nix with Catppuccin theme |
| OBS | `features/media/obs.nix` | `hm.gui` | OBS Studio, Linux only (`lib.mkIf pkgs.stdenv.isLinux`). Includes obs-pipewire-audio-capture |
| Obsidian | `features/notes/obsidian.nix` | `hm.gui` | Obsidian note-taking |
| Zathura | `features/pdf/zathura.nix` | `hm.gui` | Zathura PDF viewer |
| Gaming apps | `features/gaming/home.nix` | `hm.gaming` | Lutris, Bottles, Heroic launcher |

---

## System Services

NixOS-level opt-in services.

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| AMD GPU | `features/amdgpu/` | `nixos.amdgpu` | AMD GPU via `hardware.amdgpu`, ROCm for compute, OpenGL, Vulkan |
| NVIDIA GPU | `features/nvidia/` | `nixos.nvidia` | NVIDIA proprietary drivers, modesetting, power management |
| Gaming | `features/gaming/nixos.nix` | `nixos.gaming` | Steam with Proton, GameMode, MangoHud, Wine |
| Docker | `features/docker/` | `nixos.docker` | Docker daemon, adds user to `docker` group |
| Tailscale | `features/tailscale/` | `nixos.tailscale` | Tailscale VPN service, opens firewall UDP 41641 |
| Server / DNS | `features/server/dns.nix` | `nixos.server` | Blocky DNS with ad-blocking + Unbound recursive resolver, Prometheus metrics |

---

## Darwin-Specific

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| Darwin base | `features/darwin/` | `darwin.base` | macOS system config: Dock, Finder, keyboard remapping (CapsLock to Control), dark mode, Homebrew with auto-cleanup, user shell, sops-nix secrets |
