<p align="center">
  <img src="https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExdTRyYWtzdHBidGNrbjFmMTlleG8zZHdhOXVyOThvdWpleGllNWI1YyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/AWqRqyyLYhZxS/giphy.gif" alt="Ein" width="300"/>
</p>

## Contents

- [Overview](#overview)
- [Profiles Selected](#profiles-selected)
- [Variables](#variables)
- [Homebrew Casks](#homebrew-casks)
- [Host-Specific Files](#host-specific-files)

---

## Overview

**Platform:** aarch64 Darwin (Apple Silicon)
**Role:** MacBook, full configuration

Managed through nix-darwin and Homebrew. Same shell, same tools, same theme as the NixOS machines.

---

## Profiles Selected

```nix
# modules/hosts/darwin/ein/imports.nix
imports = with config.flake.modules.darwin; [base eyecandy];
```

Darwin's `base` profile covers: macOS system defaults, Homebrew management, sops-nix secrets, home-manager wiring, Stylix theming, and the `var` schema.

---

## Variables

```nix
var = {
  username = "arturo";
  hostname = "ein";
  shell    = "zsh";
  terminal = "ghostty";
  browser  = "zen";
};
```

---

## Homebrew Casks

```
brave-browser, claude, discord, docker-desktop, ghostty,
httpie-desktop, lm-studio, raycast, steam, tailscale-app, utm, whatsapp
```

---

## Host-Specific Files

| File | Purpose |
|------|---------|
| `imports.nix` | Profile selection |
| `variables.nix` | `var.*` values |
| `hostname.nix` | Sets `networking.hostName` and `networking.computerName` |
| `homebrew.nix` | macOS-only Homebrew casks |
| `home.nix` | Ein-specific HM packages (claude-code, opencode) |
