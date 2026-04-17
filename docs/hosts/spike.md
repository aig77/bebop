<p align="center">
  <img src="https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDhtOHljdjB5ZWlmc3lhMmRvNGRuZ2t4OWU1eDY1cWM3aW5sdm54ZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/gQbVzXQQbGO7C/giphy.gif" alt="Spike" width="300"/>
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
