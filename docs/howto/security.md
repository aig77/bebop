# Security

Where the homelab defends itself: exposure, vulnerability scanning, log aggregation, and alerting. This page is the readout for "how do I know my boxes are not compromised."

## Contents

- [Threat Model](#threat-model)
- [Vulnerability Scanning](#vulnerability-scanning)
- [Alerting](#alerting)
- [Updating](#updating)
- [Incident Readout](#incident-readout)

---

## Threat Model

The fleet trusts three layers, in order:

1. Cloudflare edge (public services via tunnel)
2. Tailnet ACLs (every host, plus `tailscale serve` for private services)
3. The LAN (subnet router routes, DNS, `nodeExporter`, Loki push)

Nothing exposes 80/443 directly. `services.openssh` is reachable over the tailnet and LAN; everything else listens on loopback or is firewalled to specific peers. The highest-value attack surface is the tailnet itself: any device admitted to it can attempt SSH and reach private services. Keeping tailnet membership tight is the first line of defense.

## Vulnerability Scanning

Two scanners run nightly from systemd timers, no manual action:

### vulnix - system closure

`modules/features/vulnix.nix`, enabled by the `server` bundle on `jet` and `ed`.

- Scans the transitive closure of `/run/current-system` against the NVD feed.
- NVD cache persists at `/var/lib/vulnix/nvd`; first run downloads years of data, then incremental.
- Runs with `--json`: raw results at `/var/lib/vulnix/report.json`, human readout at `/var/lib/vulnix/report.txt` (per-derivation blocks grouping CVEs by severity bucket from CVSSv3, then a `TOTALS` line). Severities: critical ≥ 9, high ≥ 7, medium ≥ 4, low > 0, unknown = no score.
- Discord on CRITICAL/HIGH: `**Vulnix System Scan**`, `N CVEs across P derivation(s)`, an emoji severity row (🔴 critical, 🟠 high, 🟡 medium, 🟢 low, ⚪ unknown), plus `vulnix-report.txt` attached. MEDIUM/LOW/unknown-only runs record to the file but stay silent.
- Exit codes: `0` clean or no crit/high, `1` crit/high found (writes `/var/lib/vulnix/vulns-found` + Discord), `2` scanner error (no Discord). vulnix exits 2 for both findings and runtime errors, so the split is done by stderr content (`error.log`) and JSON, not exit status.
- Whitelist: TOML, in the `whitelist` binding at the top of `modules/features/vulnix.nix`. Sections are keyed `["pkg"]` or `["pkg-1.2.3"]` with `cve = [...]` (a wildcard `["*"]` section must carry at least one CVE). The `.toml` filename suffix is load-bearing: vulnix picks the format by extension, and a comment-only file fails its content heuristic. Only whitelist verified false positives or genuinely unfixable-at-pin advisories, and re-check each entry (`nix shell nixpkgs#vulnix -- vulnix --system`) before trusting it. Mutable whitelists rot into real holes.

Manual run:

```bash
sudo systemctl start vulnix-scan.service
cat /var/lib/vulnix/report.txt
```

### trivy - container images

`modules/features/trivy.nix`, imported by `jet` only (the only host running containers).

- Enumerates live images from the rootful podman store (`subtrakr` and anything else podman runs) and scans what is actually pulled. Nothing is hardcoded: future podman images get covered the day they exist.
- Each image is saved to tar and scanned with `trivy image --input --format json --quiet`, `--ignore-unfixed --exit-code 1`, all severities (no `--severity` filter).
- Cache/DB in `/var/lib/trivy`. Each run rebuilds `/var/lib/trivy/report.txt` with a per-image breakdown: `CRITICAL`/`HIGH`/`MEDIUM`/`LOW` blocks carrying the unique CVE list, then a `TOTALS` line (`N CVEs across M image(s)`). Full details live there and in journald (and therefore Loki).
- Discord on CRITICAL/HIGH: `**Trivy Image Scan**`, `N CVEs across M image(s)`, an emoji severity row (🔴 critical, 🟠 high, 🟡 medium, 🟢 low), plus `trivy-report.txt` attached. MEDIUM/LOW-only runs record to the file but stay silent.
- Exit codes: `0` clean or no crit/high, `1` crit/high found (Discord + attachment), `2` scanner error (no Discord; the failed unit is visible in `systemctl list-timers` and the trivy stderr is in journald). Findings and operational errors are never conflated.

Manual run:

```bash
sudo systemctl start trivy-image-scan.service
cat /var/lib/trivy/report.txt
journalctl -u trivy-image-scan.service
```

## Alerting

- Gatus (jet) already alerts Discord on service failure; public services are checked on their public URLs.
- vulnix alerts when the system closure has CRITICAL/HIGH CVEs (severity-bucketed readout + `vulnix-report.txt` attached).
- trivy alerts when an image has CRITICAL/HIGH CVEs (four-severity breakdown + `trivy-report.txt` attached).
- Healthchecks.io pings keep the hosts declaratively alive.

The webhook secret is the shared `discord/ein-webhook` sops entry, reused across gatus, n8n, vulnix, and trivy.

## Updating

No automation bumps `flake.lock`; updates are manual by design so nothing deploys without a human:

```bash
nix flake update
nix flake check
# review, then deploy
nh os switch -H jet
nh os switch -H ed
```

Cadence: monthly, or immediately after a security advisory you care about. nixpkgs channels backport security fixes faster than full releases, so staying near the branch head on both channels is most of the battle.

## Incident Readout

1. Check timers actually fired: `systemctl list-timers | grep -E 'vulnix|trivy'`.
2. Scanner reports: `/var/lib/vulnix/report.txt`, `journalctl -u trivy-image-scan.service`.
3. Rotation never includes the secrets file (`modules/aspects/secrets/secrets.yaml` is sops-encrypted; see [Secrets](secrets.md)).
