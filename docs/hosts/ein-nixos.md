<p align="center">
  <img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExdTRyYWtzdHBidGNrbjFmMTlleG8zZHdhOXVyOThvdWpleGllNWI1YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/AWqRqyyLYhZxS/giphy.gif" alt="Ein" width="300"/>
</p>

## Contents

- [Overview](#overview)
- [Hardware](#hardware)

---

## Overview

**Platform:** x86_64 NixOS
**Role:** Framework Pro Laptop 

Full-featured desktop with Hyprland and niri on Wayland, AMD GPU, gaming, and development tooling. Catppuccin Mocha everywhere.

- Hyprland + niri, Noctalia
- Gaming: Steam with Proton, Heroic, Bottles, GameMode, MangoHud
- Ghostty, Neovim, Tmux, Docker
- Spotify (Spicetify), Discord (Nixcord), Obsidian, OBS, Zen browser
- Declarative disk partitioning via Disko (btrfs with subvolumes)
- Slight differences to desktop including remapping right control key to super and VPN

---

## Hardware

- **CPU:** Intel (x86_64)
- **GPU:** Intel (iGPU)
- **Boot:** systemd-boot with EFI
- **Disk:** GPT, 1G ESP + btrfs root with `@`, `@home`, `@nix`, `@snapshots`, `@log`, `@cache` subvolumes
