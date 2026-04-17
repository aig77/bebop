<p align="center">
  <img src="https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExN3lydDhpM3dqbTU2azI0aGxmZ3F2ZjVqdWgxc2VtYTA5bzloOHQ4ciZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/10VjiVoa9rWC4M/giphy.gif" alt="Faye" width="300"/>
</p>

## Contents

- [Overview](#overview)
- [Hardware](#hardware)
- [Profiles Selected](#profiles-selected)
- [Variables](#variables)
- [Host-Specific Files](#host-specific-files)

---

## Overview

**Platform:** x86_64 NixOS
**Role:** Daily driver desktop workstation

Full-featured desktop with Hyprland on Wayland, AMD GPU, gaming, and development tooling. Catppuccin Mocha everywhere.

- Hyprland compositor with custom animations, blur, and rounded corners
- Quickshell bar, SwayNC notification center, Fuzzel launcher, Hyprlock lock screen, Wlogout
- Gaming: Steam with Proton, Heroic, Bottles, GameMode, MangoHud
- Ghostty terminal, Zen browser, Neovim, Tmux
- Spotify (Spicetify), Discord (Nixcord), Obsidian, OBS
- Declarative disk partitioning via Disko (btrfs with subvolumes)

---

## Hardware

- **CPU:** AMD (x86_64)
- **GPU:** AMD (ROCm, Vulkan)
- **Boot:** systemd-boot with EFI
- **Disk:** GPT, 1G ESP + btrfs root with `@`, `@home`, `@nix`, `@snapshots`, `@log`, `@cache` subvolumes
- **Kernel modules:** nvme, xhci_pci, ahci, usbhid, usb_storage, sd_mod, kvm-amd
- **Audio interface:** Universal Audio Volt 476 (pinned to stereo profile via `volt` aspect)

---

## Profiles Selected

```nix
# modules/hosts/nixos/faye/imports.nix
imports = with config.flake.modules.nixos; [
  base
  desktop
  hyprland-quickshell
  amdgpu
  gaming
  docker
  tailscale
  volt              # pins Volt 476 to stereo profile on connect
];
```

HM profiles activated automatically via the bridge:

`hm.shell` + `hm.gui` + `hm.hyprland` + `hm.fuzzel` + `hm.hyprlock` + `hm.hypridle` + `hm.screenshot` + `hm.gaming`

---

## Variables

```nix
var = {
  username      = "arturo";
  hostname      = "faye";
  location      = "Miami";       # used by weather widget
  shell         = "zsh";
  terminal      = "ghostty";
  browser       = "zen";
  fileManager   = "thunar";
  lock          = "hyprlock";
  wallpaperEngine = "awww";
};
```

---

## Host-Specific Files

| File | Purpose |
|------|---------|
| `imports.nix` | Profile selection |
| `variables.nix` | All `var.*` values |
| `hardware.nix` | Kernel modules, AMD microcode, hostPlatform |
| `disko.nix` | Disk layout for fresh installs (nixos-anywhere) |
| `home.nix` | Faye-specific HM packages: rustc, go, python3, bitwarden, lmstudio, etc. |
| `state-version.nix` | `system.stateVersion = "25.05"` |

### Fresh install

See the comment block at the top of `disko.nix` for the full `nixos-anywhere` command. Running it with `--generate-hardware-config nixos-facter` will partition the disk, install NixOS, and generate `facter.json`. After that, `hardware.nix` can be replaced by `facter.nix` + `facter.json`.
