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
| Hyprland | `features/hyprland/` | `nixos.hyprland`, `hm.hyprland` | System enablement + portals (nixos.nix), keybinds/animations/window rules + HyprPanel bar (home.nix). Uses `var.*` for terminal, browser, launcher, lock, logout |
| Hyprland + Quickshell | `features/quickshell/` | `nixos.hyprland-quickshell`, `hm.quickshell` | Hyprland with Quickshell as the bar/launcher |
| Niri | `features/niri/` | `nixos.niri`, `hm.niri` | GDM + Niri session (nixos.nix), keybinds/rules/wallpaper (home.nix), niri-specific Waybar (waybar.nix) |
| GNOME | `features/gnome/` | `nixos.gnome`, `hm.gnome` | GDM + GNOME packages (nixos.nix), shell extensions via dconf (extensions.nix) |

---

## Desktop Components

Standalone components composable across multiple WM setups.

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| HyprPanel | `features/hyprpanel/` | `hm.hyprland` | Bar config; layout varies by hostname. Weather widget reads API key via `osConfig.sops.templates` |
| Waybar | `features/waybar/` | `hm.waybar` | Status bar for niri (hyprland uses HyprPanel) |
| SwayNC | `features/swaync/` | `hm.hyprland` | Notification center/daemon |
| Hyprlock | `features/hyprlock/` | `hm.hyprlock` | Lock screen with Stylix-themed background from `var.wallpaperPath`, blur |
| Hypridle | `features/hypridle/` | `hm.hypridle` | Idle daemon: dim at 4min, lock at 5min, suspend at 10min |
| Fuzzel | `features/fuzzel/` | `hm.fuzzel` | App launcher shared between Hyprland and niri |
| Quickshell | `features/quickshell/` | `hm.quickshell` | Quickshell bar/launcher widget framework |
| Wallpaper | `features/wallpaper/` | `hm.wallpaperManager` | Three-file split: `swww.nix` (daemon + restore service), `waypaper.nix` (GTK picker + `post_command` symlink), `default.nix` (composite profile). Config written via `home.activation` so it stays writable at runtime |
| Screenshot | `features/screenshot/` | `hm.screenshot` | grimblast scripts bound to Print keys |
| File manager | `features/file-manager/` | `hm.gui` | Thunar with archive and media tag plugins |
| Custom desktop shell | `features/customDesktopShell/` | | Custom shell integration utilities |
| Eyecandy | `features/eyecandy/` | `darwin.eyecandy`, `hm.base` | fastfetch, cava audio visualizer, krabby fetch alias, extra packages |

---

## Applications

All Home Manager modules. Most contribute to `hm.base` or `hm.gui`.

### Shell and Terminal

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| ZSH | `features/shell/zsh.nix` | `hm.base` | Completions, autosuggestions, syntax highlighting, vi mode, fzf-tab |
| Fish | `features/shell/fish.nix` | `hm.base` | Fish shell config and abbreviations |
| Starship | `features/shell/starship.nix` | `hm.base` | Cross-shell prompt |
| Direnv | `features/shell/direnv.nix` | `hm.base` | Automatic dev shell activation with nix-direnv |
| FZF | `features/shell/fzf.nix` | `hm.base` | Fuzzy finder with shell integration |
| Zoxide | `features/shell/zoxide.nix` | `hm.base` | Smart `cd` replacement |
| Tmux | `features/shell/tmux.nix` | `hm.base` | Tmux with Catppuccin theme |
| CLI packages | `features/shell/packages.nix` | `hm.base` | ripgrep, fd, bat, eza, jq, htop, wget, curl, unzip, etc. |
| Ghostty | `features/terminal/ghostty.nix` | `hm.base` | Ghostty terminal (Stylix handles colors) |
| Alacritty | `features/terminal/alacritty.nix` | `hm.base` | Alacritty as fallback terminal |

### Editors and Version Control

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
| Neovim | `features/editor/neovim.nix` | `hm.base` | LSP, treesitter, mini.nvim, mason |
| Vim | `features/editor/vim.nix` | `hm.base` | Minimal vim config as fallback |
| Git | `features/git/git.nix` | `hm.base` | Username from `var.username`, email from sops secret at runtime |
| Lazygit | `features/git/lazygit.nix` | `hm.base` | Lazygit TUI with Catppuccin theme |

### GUI Applications

| Feature | Path | Profile | Description |
|---------|------|---------|-------------|
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
