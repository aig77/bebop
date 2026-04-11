# Aspects

## Contents

- [What Are Aspects](#what-are-aspects)
- [Reference](#reference)

---

## What Are Aspects

Aspects are foundational system concerns applied broadly. They define what the system is at a base level, not what it can optionally do. An aspect isn't something a host picks up for a specific capability; it's a concern that belongs to every machine in its category (all NixOS machines, all desktop machines, etc.).

Aspects live in `modules/aspects/` and contribute to the `base` and `desktop` NixOS profiles, or to profiles that represent hardware reality rather than an optional capability.

See [Features](features.md) for opt-in capabilities.

---

## Reference

| Aspect | Path | Profile | Description |
|--------|------|---------|-------------|
| `nix` | `aspects/nix/` | `nixos.base` | Nix daemon settings: flakes, nix-command, auto-optimise-store, auto-gc, trusted users, substituters (nixos.org + hyprland cache) |
| `users` | `aspects/users/` | `nixos.base` | Primary user account from `var.username`, shell enablement, groups (networkmanager, audio, video, etc.), sudo |
| `networking` | `aspects/networking/` | `nixos.base` | NetworkManager, firewall with ports 22/80/443 open |
| `secrets` | `aspects/secrets/` | `nixos.base` | sops-nix: `defaultSopsFile = ./secrets.yaml`, age key at `~/.config/sops/age/keys.txt`, secret declarations, weatherapi.json template (Linux only) |
| `boot` | `aspects/boot/` | `nixos.desktop` | systemd-boot with EFI, GRUB2 theme, Plymouth boot splash |
| `audio` | `aspects/audio/` | `nixos.desktop` | PipeWire with PulseAudio compatibility, rtkit for real-time audio, dbus |
| `bluetooth` | `aspects/bluetooth/` | `nixos.desktop` | `services.bluetooth` enabled, `blueman` applet |
| `theme` | `aspects/theme/` | `nixos.desktop` / `darwin.base` | Stylix: Catppuccin Mocha, JetBrains Mono Nerd Font, DejaVu Sans/Serif, Noto Color Emoji, catppuccin-mocha-light cursors, Papirus Dark icons. Wallpaper is not managed here; it's set at runtime by waypaper + awww |
| `desktop` (HM wiring) | `aspects/desktop/home.nix` | `nixos.desktop` | Wires `hm.gui`, `hm.eyecandyNixos`, `hm.nvimStylix` into the desktop profile. Separated from the system-level desktop aspects since `desktop` has no single owning directory. |

### Flake-level infrastructure

These live in `modules/flake/` rather than `aspects/` because they are flake-parts plumbing, not system concerns:

| Module | Path | Description |
|--------|------|-------------|
| `var` | `flake/var/` | Variable schema definition (`options.var.*`) contributed to base profiles |
| `owner` | `flake/owner/` | `flake.meta.owner.username`, the single place to set the primary username |
| home-manager bridges | `flake/home-manager/` | Wires NixOS/Darwin profiles to Home Manager profiles |

### Faye-specific

| Aspect | Path | Profile | Description |
|--------|------|---------|-------------|
| `volt` | `aspects/audio/volt.nix` | `nixos.volt` | WirePlumber rule that pins the Universal Audio Volt 476 to `analog-surround-40` on connect. Without this, WirePlumber defaults to `pro-audio`, which breaks Discord and normal apps. Switch to `pro-audio` manually via `pactl set-card-profile` when using a DAW |
