# Spike

## Contents

- [Overview](#overview)
- [Profiles Selected](#profiles-selected)
- [Variables](#variables)
- [Homebrew Casks](#homebrew-casks)
- [Host-Specific Files](#host-specific-files)

---

## Overview

**Platform:** aarch64 Darwin (Apple Silicon)
**Role:** MacBook, lean configuration

Same foundation as Ein with a trimmer app set. Same shell, same dev tools, same theming.

---

## Profiles Selected

```nix
# modules/hosts/darwin/spike/imports.nix
imports = with config.flake.modules.darwin; [base];
```

No `eyecandy` profile. Spike is the leaner of the two Mac configurations.

---

## Variables

```nix
var = {
  username = "arturo";
  hostname = "spike";
  shell    = "zsh";
  terminal = "ghostty";
  browser  = "zen";
};
```

---

## Homebrew Casks

```
claude, discord, docker-desktop, ghostty, lm-studio,
proton-mail-bridge, raycast, tailscale-app, zen-browser
```

---

## Host-Specific Files

| File | Purpose |
|------|---------|
| `imports.nix` | Profile selection |
| `variables.nix` | `var.*` values |
| `hostname.nix` | Sets `networking.hostName` and `networking.computerName` |
| `homebrew.nix` | macOS-only Homebrew casks |
| `home.nix` | Spike-specific HM packages (opencode) |
