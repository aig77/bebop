# Ed

## Contents

- [Overview](#overview)
- [Profiles Selected](#profiles-selected)
- [Variables](#variables)
- [Host-Specific Files](#host-specific-files)

---

## Overview

**Platform:** aarch64 NixOS
**Role:** Headless Raspberry Pi server

Handles network services. No GUI, no desktop. Just DNS and monitoring running quietly.

- Blocky DNS server with ad-blocking (StevenBlack hosts list)
- Unbound recursive resolver with DNSSEC
- Prometheus metrics collection
- Grafana dashboards for monitoring
- Auto-expanding root partition, watchdog for auto-reboot
- Builds as a flashable SD card image (`nix build .#images.ed`)

---

## Profiles Selected

```nix
# modules/hosts/nixos/ed/imports.nix
imports = with config.flake.modules.nixos; [
  base
  tailscale
  server
];
nixpkgs.hostPlatform = "aarch64-linux";
```

Platform is set inline in `imports.nix`. No separate `hardware.nix` needed for a server without complex hardware config.

---

## Variables

```nix
var = {
  username = "arturo";
  hostname = "ed";
  shell    = "zsh";
};
```

---

## Host-Specific Files

| File | Purpose |
|------|---------|
| `imports.nix` | Profile selection + `nixpkgs.hostPlatform` |
| `variables.nix` | `var.*` values |
| `config.nix` | SSH settings, firewall, OpenSSH configuration |
| `home.nix` | Minimal server packages |
| `state-version.nix` | `system.stateVersion = "25.05"` |
