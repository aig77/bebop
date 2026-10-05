<p align="center">
  <img src="https://media1.tenor.com/m/5lFKTvSNpaQAAAAd/jet-black-jet-black-laugh.gif" alt="Jet" width="300"/>
</p>

## Contents

- [Overview](#overview)
- [Disk Layout](#disk-layout)
- [Backups](#backups)
- [Data Migration](#data-migration)

---

## Overview

**Platform:** x86_64 NixOS
**Role:** Homelab server - self-hosted services on the public internet via Cloudflare or privately accessible via Tailnet.

Runs services as native NixOS services or Podman containers.
Exposed either publicly through Cloudflare-proxied subdomains with TLS handled by Caddy,
or privately accessible via Tailnet.
Service data backups are handled by restic which upload updated versions of critical data files to a Cloudflare R2 bucket.

List of services located in server [imports](../modules/hosts/nixos/jet/imports.nix)
Deploying this host: see [deploying](../howto/deploying.md) and [age keys](../howto/age-keys.md).

Monitors ed over the tailnet: gatus health checks and prometheus scrape targets resolve ed through `config.var.network.addrOf "ed"` (MagicDNS), no hardcoded IPs.

__Invidious requires either a complete migration to a docker setup or being dropped__

---

## Disk Layout

Two NVMe drives in mdadm RAID1 with BTRFS on top. One drive can fail and be swapped
with no data loss. GRUB is installed to both drives declaratively via
`boot.loader.grub.mirroredBoots` ensures every `nh os switch` keeps both drives in sync.

```text
/dev/nvme0n1
  nvme0n1p1  1G   vfat    /boot          (primary EFI)
  nvme0n1p2  rest mdadm   \
                            md0  (RAID1)  -> BTRFS
/dev/nvme1n1                /
  nvme1n1p1  1G   vfat    /boot/efi-backup  (backup EFI)
  nvme1n1p2  rest mdadm   /
```

BTRFS subvolumes on the RAID array:

| Subvolume | Mountpoint | Purpose |
|-----------|------------|---------|
| `@` | `/` | Root |
| `@home` | `/home` | User home |
| `@nix` | `/nix` | Nix store |
| `@data` | `/var/lib` | Service state |
| `@log` | `/var/log` | Logs |

**Drive failure recovery:**
```bash
mdadm --manage /dev/md0 --add /dev/nvme1n1p2
mdadm --wait /dev/md0
```

---

## Backups

Service data is backed up with restic to a Cloudflare R2 bucket (S3-compatible).

- **Module:** `modules/features/backup.nix` -> `flake.modules.nixos.backup`
- **Schedule:** daily at 02:00 via a persistent systemd timer (`services.restic.backups.jet`)
- **Credentials:** R2 repository URL, access key, and restic password injected from sops
- **What gets backed up:** any service that declares a `backup` block in `var.services`. Each service stages a consistent snapshot (e.g. `pg_dump` for PostgreSQL, sqlite `.backup` plus attachments) into `/var/lib/backups` before upload, then that staging dir is cleaned up afterwards
- **Retention:** pruned automatically, keeping daily backups for 7 days, weekly for 4 weeks, monthly for 3 months
- **Repo initialized** automatically on first run (`initialize = true`)

Restore by pointing `restic restore` at the repo with the same password and R2 credentials from the sops secret.

---

## Data Migration

Restore a service from its restic snapshot (see [Backups](#backups)).

```bash
set -a; source /run/secrets/restic.env; set +a
export RESTIC_PASSWORD="$(cat /run/secrets/restic/password)"
restic snapshots
restic restore latest --target /tmp/restore --path /var/lib/backups/<service>
```

- Plain files/dirs: copy onto the live data dir, preserve ownership/permissions.
- SQLite (sqlite3 .backup): copy the .db back or sqlite3 <db> ".restore '<staged.db>'".
- Postgres (pg_dump): sudo -u postgres pg_restore --clean -d <database> <staged.dump>.

Stop the service before applying, fix ownership, start it after.
