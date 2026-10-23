<p align="center">
  <img src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExb3RkNWthcWVjNm1wcjIxdDNmNGx6em4yYzh0anp6bTV2dmdrcTloMiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/udhngZK2IFTc4/giphy.gif" alt="Ed" width="300"/>
</p>

## Overview

**Platform:** aarch64 NixOS
**Role:** Headless Raspberry Pi server

Handles network services. No GUI, no desktop stack. Runs DNS and monitoring only.

- AdGuard Home DNS server with ad-blocking ([HaGeZi Multi PRO](https://github.com/hagezi/dns-blocklists) + TIF); its `/control/stats` JSON feeds glance's native DNS widget on jet
- AdGuard Home admin UI, served over the tailnet at `https://ed.<tailnet>/` (tailscale serve on 443 -> the plain-HTTP API port); glance shows it as the `AdGuard Home` card
- Unbound recursive resolver with DNSSEC
- Prometheus metrics collection
- Glance agent: exposes CPU / memory / disk on `ports.glanceAgent`, read by jet's server-stats widget over the tailnet
- Tailscale subnet router: advertises `net.subnet` (`192.168.68.0/24`); jet health-checks and scrapes it over the tailnet via `net.addrOf "ed"`
- Auto-expanding root partition, watchdog for auto-reboot
- Builds as a flashable SD card image (`nix build .#images.ed`)

__Plans for a flashable USB image in the future__
