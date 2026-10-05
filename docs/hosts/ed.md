<p align="center">
  <img src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExb3RkNWthcWVjNm1wcjIxdDNmNGx6em4yYzh0anp6bTV2dmdrcTloMiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/udhngZK2IFTc4/giphy.gif" alt="Ed" width="300"/>
</p>

## Overview

**Platform:** aarch64 NixOS
**Role:** Headless Raspberry Pi server

Handles network services. No GUI, no desktop stack. Runs DNS and monitoring only.

- Blocky DNS server with ad-blocking ([StevenBlack hosts list](https://github.com/StevenBlack/hosts))
- Unbound recursive resolver with DNSSEC
- Prometheus metrics collection
- Tailscale subnet router: advertises `var.network.subnet` (`192.168.68.0/24`); jet health-checks and scrapes it over the tailnet via `var.network.addrOf "ed"`
- Auto-expanding root partition, watchdog for auto-reboot
- Builds as a flashable SD card image (`nix build .#images.ed`)

__Plans for a flashable USB image in the future__
