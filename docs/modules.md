# Module Reference

Every `.nix` file in `modules/` is a flake-parts module. The outer function signature is either `_:` (no args needed) or `{lib, config, inputs, ...}:` when flake-parts-level values are needed. The body sets options in the `flake.*` or `configurations.*` namespaces.

---

## flake/

Infrastructure modules — not profiles, just plumbing.

### `flake/flake-parts.nix`
Imports `flake-parts.flakeModules.modules`, which is what enables the `flake.modules.*` option namespace across all other files. Everything depends on this being loaded first (import-tree handles ordering by merging all files).

### `flake/nixosConfigurations.nix`
Defines the `configurations.nixos` option and maps it to `flake.nixosConfigurations`. Every NixOS host registers itself via `configurations.nixos.<name>.module`; this builder picks them all up and calls `nixpkgs.lib.nixosSystem` for each. Automatically includes `sops-nix` and `stylix` NixOS modules for all hosts.

### `flake/darwinConfigurations.nix`
Same pattern for Darwin. Automatically includes `home-manager`, `nix-homebrew`, `sops-nix`, and `stylix` Darwin modules for all Darwin hosts. Note: `inputs.self` is removed from `specialArgs` to avoid infinite recursion in nix-darwin.

### `flake/systems.nix`
Declares `systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"]` for `perSystem` outputs.

### `flake/formatter.nix`
Sets `alejandra` as the flake formatter (`nix fmt`).

### `flake/pre-commit.nix`
Configures pre-commit hooks: `alejandra` (formatting), `statix` (linting), `deadnix` (dead code). Runs automatically on `git commit` and as a flake check.

### `flake/shell.nix`
Dev shell with pre-commit installed. Enter with `nix develop`.

---

## owner/

### `owner/default.nix`
Defines `flake.meta.owner.username = "arturo"`. This is used by `home-manager/base.nix` and the HM bridge modules to set the home-manager username without hardcoding it in every place. To change the primary username, only this file needs updating.

---

## var/

Configuration variables that hosts set and modules read. This is the interface between host config and feature modules — modules should use `var.*` instead of hardcoding hostnames or usernames.

### `var/default.nix`
Contributes the `options.var` schema to `flake.modules.nixos.base`. Available options:

| Option | Type | Default | Description |
|---|---|---|---|
| `var.username` | str | — | System username |
| `var.hostname` | str | — | Machine hostname |
| `var.shell` | enum | — | `"zsh"` or `"fish"` |
| `var.terminal` | str | `"ghostty"` | Default terminal |
| `var.browser` | str | `"zen"` | Default browser |
| `var.location` | str | `""` | City for weather widgets |
| `var.launcher` | str | `"fuzzel"` | App launcher (`"fuzzel"` or `"rofi"`) |
| `var.fileManager` | str | `"nautilus"` | File manager |
| `var.lock` | str | `"hyprlock"` | Lock screen command |
| `var.logout` | str | `"wlogout"` | Logout menu command |

### `var/darwin.nix`
Same but contributes to `flake.modules.darwin.base`. Darwin has a smaller set: `username`, `hostname`, `shell`, `terminal`, `browser`.

---

## home-manager/

These modules are the bridge between flake-parts (outer context) and Home Manager (inner context). They're the only place where `config.flake.modules.homeManager.*` is referenced from flake-parts level to wire HM profiles into NixOS/Darwin.

### `home-manager/base.nix`
Contributes to `flake.modules.homeManager.base`. Sets `home.username` from `config.flake.meta.owner.username` (flake-parts context) and enables `programs.home-manager`. This is the minimal HM config every user gets.

### `home-manager/nixos.nix`
**The NixOS↔HM bridge.** At flake-parts level it reads `config.flake.modules.homeManager.*` and wires them into NixOS `home-manager.users.<username>` imports. Defines which HM profiles are loaded per NixOS profile:

| NixOS profile | HM profiles loaded |
|---|---|
| `base` | `hm.base` |
| `desktop` | `hm.gui` |
| `hyprland` | `hm.hyprland`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle`, `hm.screenshot` |
| `niri` | `hm.niri`, `hm.waybar`, `hm.mako`, `hm.fuzzel`, `hm.hyprlock`, `hm.hypridle` |
| `gnome` | `hm.gnome` |
| `gaming` | `hm.gaming` |

Also passes `var` and `inputs` into HM's `extraSpecialArgs` so HM modules can use `var.*` and `inputs.*` directly.

### `home-manager/darwin.nix`
**The Darwin↔HM bridge.** Wires `hm.base` and `hm.gui` into Darwin's `home-manager.users.<username>`. Darwin always gets both since there's no headless Darwin configuration here.

---

## hosts/

Each host is a directory of flake-parts modules that all contribute to the same `configurations.<platform>.<hostname>.module` deferredModule. Split into multiple files for clarity rather than one big file.

### NixOS host: `faye`

Full desktop machine. x86_64, AMD GPU, Hyprland.

| File | Purpose |
|---|---|
| `imports.nix` | Selects named profiles: `base desktop hyprland amdgpu gaming docker tailscale` |
| `variables.nix` | Sets all `var.*` values: hostname=faye, location=Miami, shell=zsh, etc. |
| `hardware.nix` | Kernel modules (nvme, xhci_pci, etc.), AMD microcode, hostPlatform, DHCP |
| `disko.nix` | Disk layout: GPT, 1G ESP + btrfs root with @, @home, @nix, @snapshots, @log, @cache subvolumes |
| `home.nix` | Faye-specific HM packages: dev tools (rustc, go, python3), GUI apps (bitwarden, brave, lmstudio, etc.) |
| `state-version.nix` | `system.stateVersion = "25.05"` |

**Fresh install:** See the comment block at the top of `disko.nix` for the `nixos-anywhere` command. Running it with `--generate-hardware-config nixos-facter` generates `facter.json` on the target and replaces the need for `hardware.nix`.

### NixOS host: `ed`

Headless ARM server. aarch64-linux.

| File | Purpose |
|---|---|
| `imports.nix` | Profiles: `base tailscale server`. Also sets `nixpkgs.hostPlatform = "aarch64-linux"` directly — no hardware.nix needed since it's set inline |
| `variables.nix` | hostname=ed, shell=zsh |
| `config.nix` | SSH, firewall, OpenSSH settings |
| `home.nix` | Minimal server packages |
| `state-version.nix` | `system.stateVersion = "25.05"` |

Note: `ed` sets `nixpkgs.hostPlatform` directly in `imports.nix` rather than having a `hardware.nix`, since it's a server without complex hardware config.

### Darwin host: `ein`

MacBook. aarch64-darwin.

| File | Purpose |
|---|---|
| `imports.nix` | Profiles: `base` only |
| `variables.nix` | hostname=ein, shell=zsh |
| `homebrew.nix` | macOS-only casks: cursor, orbstack, raycast, wezterm, etc. |
| `hostname.nix` | Sets `networking.hostName` and `networking.computerName` |
| `home.nix` | Merges home packages: claude-code, opencode |

### Darwin host: `spike`

MacBook. aarch64-darwin.

Same structure as `ein`. Homebrew casks include proton-mail-bridge. Packages: opencode only.

---

## secrets/

### `secrets/default.nix`
Contributes to `flake.modules.nixos.base`. Configures sops-nix:
- `defaultSopsFile = ./secrets.yaml` — encrypted secrets live right next to this file
- Age key at `~/.config/sops/age/keys.txt`
- Declares secrets: `git-email`, `openweather-api-key`, `weatherapi-key`
- Creates a `weatherapi.json` template (Linux only) that renders the decrypted API key into a JSON file readable by hyprpanel

The Darwin equivalent is in `darwin/default.nix` and points to `../secrets/secrets.yaml` (one level up since it lives in `modules/darwin/`).

### `secrets/secrets.yaml`
The encrypted YAML file. Edit with `sops modules/secrets/secrets.yaml`. All four machines' age keys can decrypt it (defined in `.sops.yaml`).

---

## theme/

### `theme/linux.nix`
Contributes to `flake.modules.nixos.desktop`. Configures Stylix with Catppuccin Mocha, JetBrains Mono Nerd Font, DejaVu Sans/Serif, Noto Color Emoji, a fetched wallpaper, and catppuccin-mocha-light cursors with Papirus Dark icons.

### `theme/darwin.nix`
Contributes to `flake.modules.darwin.base`. Same fonts and color scheme, but no wallpaper or cursor/icon config (macOS handles those differently).

---

## System modules (NixOS)

### `nix/default.nix`
Contributes to `nixos.base`. Nix daemon settings: flakes + nix-command experimental features, auto-optimise-store, auto-gc, trusted users, substituters (cache.nixos.org + hyprland cache).

### `users/default.nix`
Contributes to `nixos.base`. Creates the primary user from `var.username`, enables zsh/fish, sets up groups (networkmanager, audio, video, etc.), enables sudo.

### `networking/default.nix`
Contributes to `nixos.base`. Enables NetworkManager, firewall (open ports 22, 80, 443).

### `boot/default.nix`
Contributes to `nixos.desktop`. Systemd-boot with EFI, grub2 theme, Plymouth boot splash.

### `audio/default.nix`
Contributes to `nixos.desktop`. PipeWire with PulseAudio compatibility, rtkit for real-time audio, dbus.

### `bluetooth/nixos.nix`
Contributes to `nixos.desktop`. Enables `services.bluetooth`, installs `blueman` applet.

### `amdgpu/default.nix`
Contributes to `nixos.amdgpu`. AMD GPU via `hardware.amdgpu`, ROCm support for compute, OpenGL, Vulkan.

### `nvidia/default.nix`
Contributes to `nixos.nvidia`. NVIDIA proprietary drivers, modesetting, power management.

### `gaming/nixos.nix`
Contributes to `nixos.gaming`. Steam with Proton, GameMode, MangoHud, Wine.

### `docker/default.nix`
Contributes to `nixos.docker`. Docker daemon, adds user to `docker` group.

### `tailscale/default.nix`
Contributes to `nixos.tailscale`. Enables `services.tailscale`, opens firewall UDP 41641.

### `server/dns.nix`
Contributes to `nixos.server`. Blocky DNS server with Unbound as upstream resolver. Prometheus metrics enabled.

---

## Desktop environment modules

### `hyprland/nixos.nix`
Contributes to `nixos.hyprland`. Enables Hyprland via `programs.hyprland`, installs `xdg-desktop-portal-hyprland`, sets up portals.

### `hyprland/home.nix`
Contributes to `homeManager.hyprland`. Full Hyprland config: keybinds, animations, window rules, monitor config, exec-once, environment variables. Uses `var.*` for terminal, browser, launcher, lock, logout commands. Includes a `view-binds` script that shows all annotated keybinds in fuzzel.

### `hyprland/hyprpanel.nix`
Contributes to `homeManager.hyprland`. HyprPanel bar config: layout varies by hostname (faye gets network/bluetooth modules, others don't). Weather widget reads API key via `osConfig.sops.templates."weatherapi.json".path` — note the use of `osConfig` to access NixOS options from within HM.

**Niche detail:** `osConfig` is the NixOS config accessible from within a Home Manager module. Regular `config` inside HM refers to the HM config. This is necessary here because `sops.templates` is a NixOS option, not a HM option.

### `niri/nixos.nix`
Contributes to `nixos.niri`. Enables niri via `inputs.niri.nixosModules.niri`, applies niri overlay, sets up GDM display manager with niri session, xdg portals with GNOME portal as backend.

### `niri/home.nix`
Contributes to `homeManager.niri`. Full niri config: keybinds mirroring Hyprland's layout, window rules, border gradients from Stylix colors (`base0D`/`base0E`), swww wallpaper daemon, waybar, hypridle, cliphist.

### `niri/waybar.nix`
Contributes to `homeManager.niri`. Waybar config specific to niri (uses `niri/workspaces` module, niri-specific IPC).

### `gnome/nixos.nix`
Contributes to `nixos.gnome`. Enables GDM and GNOME, common GNOME packages (gnome-tweaks, file-roller, etc.).

### `gnome/extensions.nix`
Contributes to `homeManager.gnome`. GNOME Shell extensions: blur-my-shell, caffeine, gsconnect, pop-shell, etc. Configured via dconf settings.

---

## Shared Wayland components

These are standalone profiles specifically so they can be composed into multiple WM setups.

### `hyprlock/default.nix`
Contributes to `homeManager.hyprlock`. Lock screen with Stylix-themed background, clock, password input, blur.

### `hypridle/default.nix`
Contributes to `homeManager.hypridle`. Idle daemon: dim screen after 4min, lock after 5min, suspend after 10min. Used by both Hyprland and niri.

### `waybar/default.nix`
Contributes to `homeManager.waybar`. Base Waybar config (used by niri; hyprland uses hyprpanel instead).

### `mako/default.nix`
Contributes to `homeManager.mako`. Notification daemon used by niri. Hyprland uses hyprpanel's built-in notifications.

### `fuzzel/default.nix`
Contributes to `homeManager.fuzzel`. App launcher shared between Hyprland and niri.

### `wlogout/default.nix`
Contributes to `homeManager.wlogout`. Logout menu. Used by niri; hyprpanel handles this for Hyprland.

### `screenshot/default.nix`
Contributes to `homeManager.screenshot`. Screenshot scripts using grimblast, bound to Print keys in both WMs.

---

## Application modules (Home Manager)

All contribute to `homeManager.base` or `homeManager.gui` unless noted.

### `shell/zsh.nix`
`homeManager.base`. Zsh with completions, autosuggestions, syntax highlighting. Stylix-aware syntax colors via `lib.mkIf (config.lib ? stylix)`.

### `shell/fish.nix`
`homeManager.base`. Fish shell config and abbreviations.

### `shell/starship.nix`
`homeManager.base`. Starship prompt, cross-shell.

### `shell/direnv.nix`
`homeManager.base`. direnv with nix-direnv for automatic dev shell activation.

### `shell/fzf.nix`
`homeManager.base`. fzf fuzzy finder with shell integration.

### `shell/zoxide.nix`
`homeManager.base`. zoxide smart `cd` replacement.

### `shell/tmux.nix`
`homeManager.base`. tmux with catppuccin theme.

### `shell/packages.nix`
`homeManager.base`. Common CLI packages: ripgrep, fd, bat, eza, jq, htop, wget, curl, unzip, etc.

### `terminal/ghostty.nix`
`homeManager.base`. Ghostty terminal emulator config. Stylix handles colors automatically.

### `terminal/alacritty.nix`
`homeManager.base`. Alacritty as fallback terminal.

### `editor/neovim.nix`
`homeManager.base`. Neovim with LSP, treesitter, mini.nvim, mason for language servers.

### `editor/vim.nix`
`homeManager.base`. Vim with a minimal plugin set as fallback.

### `git/git.nix`
`homeManager.base`. Git config: username from `var.username`, email from sops secret `git-email` (accessed at runtime via `~/.config/sops/secrets/git-email`).

### `git/lazygit.nix`
`homeManager.base`. Lazygit TUI with Catppuccin theme.

### `fetch/default.nix`
`homeManager.base`. Fastfetch system info display.

### `browser/zen.nix`
`homeManager.gui`. Zen browser with custom profile: containers, search engines, Firefox addons (uBlock Origin, Bitwarden, etc.).

### `discord/nixcord.nix`
`homeManager.gui`. Discord via Nixcord (Vencord-patched). Stylix theme applied via CSS.

### `media/spotify.nix`
`homeManager.gui`. Spotify via spicetify-nix with Catppuccin theme and extensions.

### `media/obs.nix`
`homeManager.gui`. OBS Studio — **Linux only** (`lib.mkIf pkgs.stdenv.isLinux`). OBS does not support macOS via nixpkgs. Includes `obs-pipewire-audio-capture` plugin.

### `notes/obsidian.nix`
`homeManager.gui`. Obsidian note-taking app.

### `pdf/zathura.nix`
`homeManager.gui`. Zathura PDF viewer.

### `file-manager/default.nix`
`homeManager.gui`. Thunar file manager with archive and media tag plugins.

### `rofi/default.nix`
`homeManager.gui`. Rofi launcher as alternative to fuzzel. Selected via `var.launcher = "rofi"`.

### `gaming/home.nix`
`homeManager.gaming`. Lutris, Bottles, Heroic launcher for non-Steam games.

---

## Darwin-specific modules

### `darwin/default.nix`
Contributes to `flake.modules.darwin.base`. macOS system config: disables nix (managed by nix-darwin), sets `aarch64-darwin` platform, keyboard remapping (CapsLock→Control), Dock settings, Finder settings, dark mode, homebrew with auto-cleanup, user shell, sops-nix secrets.
