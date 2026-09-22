<p align="center">
  <img src="https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDhtOHljdjB5ZWlmc3lhMmRvNGRuZ2t4OWU1eDY1cWM3aW5sdm54ZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gQbVzXQQbGO7C/giphy.gif" alt="Spike" width="300"/>
</p>

## Contents

- [Overview](#overview)
- [Hardware](#hardware)

---

## Overview

**Platform:** x86_64 NixOS
**Role:** Daily driver desktop workstation

Full-featured desktop with Hyprland and niri on Wayland, AMD GPU, gaming, and development tooling. Catppuccin Mocha everywhere.

- Hyprland + niri, Noctalia shell
- Gaming: Steam with Proton, Heroic, Bottles, GameMode, MangoHud
- Ghostty, Neovim, Tmux, Docker
- Spotify (Spicetify), Discord (Nixcord), Obsidian, OBS, Zen browser
- Declarative disk partitioning via Disko (btrfs with subvolumes)

---

## Hardware

- **CPU:** AMD (x86_64)
- **GPU:** AMD (ROCm, Vulkan)
- **Boot:** systemd-boot with EFI
- **Disk:** GPT, 1G ESP + btrfs root with `@`, `@home`, `@nix`, `@snapshots`, `@log`, `@cache` subvolumes
- **Audio interface:** Universal Audio Volt 476 (pinned to stereo profile via `volt` feature)
