# Server Services

How self-hosted services get declared, exposed, authenticated, and backed up. The heavy lifting lives in a handful of modules; this page explains how they fit together.

## The `serviceRegistry` registry

Every service feature registers itself in `serviceRegistry` (schema in `modules/flake/service-registry.nix`). A service entry looks like:

```nix
serviceRegistry.vaultwarden = {
  port = config.ports.vaultwarden;
  category = "Productivity";
  expose = {subdomain = "vault";};   # public; omit for tailnet-only
  backup = {
    paths = ["/var/lib/vaultwarden/attachments"];
    database = {type = "sqlite"; path = "/var/lib/vaultwarden/db.sqlite3";};
  };
};
```

Fields:

- `host` - the machine the service runs on; defaults to this host, so a co-located service omits it
- `port` - where the service listens; pull it from this host's port registry, never invent your own number
- `category` - functional grouping; glance renders one section per category, gatus groups endpoints by the same name (see [Categories](#categories))
- `expose` - `null` (default) for a tailnet-only service, or `{subdomain; basicAuth ? false;}` to publish it through Caddy + Cloudflare
- `servePort` - optional; HTTPS port the tailnet serves a private service on, defaults to `port` (glance sets 443)
- `serve` - `true` (default) routes a private service over the tailnet with `tailscale serve`; set `false` for entries that are monitored or backed up but are not web services (a database), where an HTTPS proxy in front of the backend protocol makes no sense. Ignored when `expose` is set
- `backup` - optional; `paths` for raw files, plus `database` for a dumpable database
- `monitor` - optional; gatus auto-registers a health check (http/tcp/dns, path, conditions, thresholds, interval). Alerts on Discord by default; set `alert = false` to track without alerting
- `homepage` - optional; glance auto-links the service (title, icon)

Ports are a **per-host registry** (`modules/flake/ports.nix` defines the option; each host fills it in `modules/hosts/nixos/<host>/server.nix`). Features read them via `config.ports.<name>`; a group like `prometheus.nodeExporter` is a nested attrset. A collision assertion rejects duplicate values at eval.

Six modules consume the registry. None of them know about individual services:

| Module | Reacts to | Effect |
|--------|-----------|--------|
| `features/caddy.nix` | `expose != null`, local | Vhost + TLS + basic auth for public services |
| `features/cloudflared.nix` | `expose != null`, local | Tunnel ingress rule for public services |
| `features/tailscale.nix` | `expose == null`, local | `tailscale serve` for private services |
| `features/backup.nix` | `backup`, local | One restic job covering all backed-up services |
| `features/gatus.nix` | `monitor.enable` (any host) | Health-check endpoint on the Bebop dashboard |
| `features/glance.nix` | `homepage.enable` (any host) | Homepage site entry |

**Locality.** Routing and backup only act on services whose `host` is this machine. Gatus and glance consume every entry, local or remote, resolving the address through `config.net.addrOf svc.host`. A non-local entry with `expose` set fails an assertion: this host's tunnel cannot reach another machine's service.

## Categories

`category` groups services by what they are for, not by where they run. The value comes from a fixed enum in the schema (`AI`, `Development`, `Infrastructure`, `Media`, `Observability`, `Productivity`), and the enum doubles as the display name.

Two consumers render it:

- **Glance** lays the page out in three columns. The narrow far-left column stacks the DNS stats widget above the server stats widget. The next two full columns hold the public services, headed by a centered globe icon (🌐), and the tailnet-only services, headed by a lock icon (🔒). The icon headings are `html` widgets at double the header font size, since columns have no title of their own. Each service column stacks one monitor widget per category, titled with the category name. Feature modules fill the far-left column through the `glance.extraWidgets` hook (see [Glance widgets](#glance-widgets)). The widget's `dynamic-columns` grid would fold the sites side by side, so CSS injected through `document.head` pins it to one site per row. Categories are ordered alphabetically, so `AI` comes first and `Productivity` last.
- **Gatus** sets the endpoint's native `group` field, so the health dashboard lists endpoints under the same names. The dashboard sorts by group.

Adding a service means picking a category; nothing else changes. A new section appears on the homepage and a new group on the dashboard automatically.

Gatus stores uptime under a `<group>_<name>` key, so an endpoint that changes group (or gets renamed) starts a fresh history in `/var/lib/gatus/data.db`. Changing a category is otherwise free and resets only that one endpoint's uptime.

The enum has one lowercase value, `other`, as the default. It sorts after every capitalized category, so it would land at the bottom of the list. An assertion rejects a service that leaves `category` at the default, so `other` never shows up in practice.

## The `net` registry

`net` (schema and data in `modules/flake/net.nix`) holds network constants:

- `subnet` - the LAN as a CIDR block, used by the subnet router
- `addrOf` - `name -> "localhost"` for this host, the hostname otherwise

Every machine is on the tailnet and resolves by MagicDNS, so there is no address book to maintain. Consumers call `config.net.addrOf svc.host`; resolution happens at request time. The fleet is the `configurations.nixos` registry, injected as `fleetHosts`; an assertion rejects a `serviceRegistry.<name>.host` that is not a known host.

A service running on another machine is registered by the consuming host as a `serviceRegistry` entry with `host = "<name>"` (and `servePort = 443` so glance links it at `https://<name>.<tailnet>`). The entry drives monitoring and homepage only; routing and backup ignore it because it is not local.

## Adding a service

1. Reserve a port in `modules/hosts/nixos/<host>/server.nix` (or reuse an existing one).
2. Create a feature that runs the app on localhost only and sets `serviceRegistry.<name>` with `port = config.ports.<name>` and `category = "..."`.
3. Choose exposure:
   - **Public**: set `expose = {subdomain = "...";}`. The host needs `server-public` (Caddy + Cloudflared). Add `basicAuth = true` to gate it.
   - **Private**: leave `expose = null` (the default). The host needs the `server` bundle (it wires in `tailscale-http`). Reachable over the tailnet, no Caddy involved. Bind the app to `127.0.0.1` (see [Private exposure](#private-exposure-tailscale-https)).
   Optionally add a `monitor` block for an automatic gatus health check, and a `homepage` block so glance links the service. Both default to off; see the field list above. A monitored service alerts on Discord unless the block sets `alert = false`.
4. `git add` the new file, run `nix flake check`.

## Public exposure: Caddy + Cloudflared

Public services are reached through a Cloudflare tunnel. The path is:

```
Client -> Cloudflare edge (TLS) -> tunnel -> cloudflared (localhost) -> Caddy (localhost) -> service
```

- **Caddy** (`features/caddy.nix`) terminates TLS with its own certs via the Cloudflare DNS-01 plugin, then reverse-proxies to `addrOf(host):<port>`. For each public service it emits a vhost for `<subdomain>.<domain>`; the domain comes from the `cloudflare/service-domain` sops secret.
- **Cloudflared** (`features/cloudflared.nix`) maps each public service to an ingress rule pointing at `https://localhost` with TLS verification disabled, since Caddy already terminated it. Each host runs its **own tunnel**: the tunnel ID and credentials live at `cloudflare/<hostname>/tunnel-id` and `cloudflare/<hostname>/tunnel-credentials`. `service-domain` and `acme-token` are zone-scoped and shared.

### Auth

With `basicAuth = true`, Caddy imports a basic auth snippet rendered from sops (`caddy/basic-auth-user`, `caddy/basic-auth-hash`). The hash is a raw bcrypt string, embedded via a template so it avoids the base64 encoding Caddy's JSON config path requires.

To rotate the password:

```bash
nix shell nixpkgs#caddy --command caddy hash-password
sops modules/aspects/secrets/secrets.yaml   # replace caddy/basic-auth-hash
nh os switch -H <host>
```

### Updating the Caddy Cloudflare plugin

Caddy is built with `withPlugins`, which compiles caddy plus the Go plugins from source. A plugin bump means updating **both** the version and the source hash:

```nix
package = pkgs.caddy.withPlugins {
  plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
  hash = "sha256-...";   # combined caddy + plugin source hash
};
```

The hash covers the whole Go module set, not just the plugin, which is why it looks unrelated to any individual plugin version. To update:

```bash
# latest revision
nix run nixpkgs#nix-prefetch-github -- caddy-dns cloudflare
# Go module version for that revision
nix shell nixpkgs#go --command go list -m github.com/caddy-dns/cloudflare@<rev>
```

Then set `hash = lib.fakeHash`, build, and copy the `got:` value from the hash mismatch error. The `@vX.Y.Z` version and the hash have to move together, so pin both in the same commit.

## Private exposure: Tailscale HTTPS

Private services (`expose = null`) are served straight over the tailnet. `features/tailscale.nix` contributes `tailscale-http`, which runs one `tailscale serve` command per local private service:

```bash
tailscale serve --bg --https=<servePort> http://addrOf(host):<port>
```

The HTTPS port defaults to the service's own `port`; a service can claim a custom one by setting `servePort`. Glance sets `servePort = 443`, so it is reachable at the bare `https://<host>.<tailnet>` with no port suffix. No caddy, no cloudflared, no firewall opening needed. `tailscale serve reset` is wired into the service stop so the whole mapping collapses on rebuild.

**Private services must bind `127.0.0.1`.** `tailscale serve` binds the service's port on the tailnet IP, so a service listening on `0.0.0.0` fights tailscaled for the socket and fails on its next restart. Set the app's listen/bind address to loopback (e.g. `services.prometheus.listenAddress = "127.0.0.1"`, `N8N_LISTEN_ADDRESS = "127.0.0.1"`).

## Logs: Loki + Alloy

The observability stack aggregates systemd journal logs. Each monitored host runs `alloy` (`modules/features/loki.nix`), which scrapes its own journal and pushes to the stack host's Loki over the tailnet:

- On the stack host, Alloy pushes to `http://127.0.0.1:<loki port>`.
- On an agent host, Alloy pushes to `https://<lokiHost>.<tailnet>:<loki port>`, through the same `tailscale serve` HTTPS path as any private service. The target comes from `LOKI_URL` in a sops-rendered env file; the tailnet suffix is the `tailscale/tailnet` secret.

Loki listens loopback-only, is registered as a tailnet-private `serviceRegistry.loki` entry (backup + gatus monitor), and Grafana provisions it as a datasource (`uid = "loki"`, used by the supplied Loki dashboard).

## Backups

Services opt in with a `backup` block. `features/backup.nix` collects every backed-up service on this host and runs a single restic job at 02:00 into a Cloudflare R2 bucket; retention is pruned automatically.

A service declares the database it owns; backup.nix generates the dump command and appends the dump path to the restic paths:

```nix
backup = {
  paths = ["/var/lib/myapp/uploads"];   # raw files, read live by restic
  database = {type = "sqlite"; path = "/var/lib/myapp/db.sqlite3";};
  # or: database = {type = "postgres"; name = "myapp";};
};
```

Database dumps are transactionally consistent (`pg_dump`, sqlite `.backup`) and safe while the service writes. Raw `paths` are read live, so a file mid-write can be captured torn; a btrfs snapshot before the run is the fix, tracked as a TODO in `modules/features/backup.nix`.

Restore:

```bash
set -a; source /run/secrets/restic.env; set +a
export RESTIC_PASSWORD="$(cat /run/secrets/restic/password)"
restic snapshots
restic restore latest --target /tmp/restore --path /var/lib/backups/<service>
```

## DNS

`features/adguard.nix` plus `features/unbound.nix` are the LAN side of the self-hosted stack (bundled as `dns`):

- **AdGuard Home** - DNS server with ad blocking. Seeded declaratively but `mutableSettings` keeps the web UI authoritative, so most settings can still be changed from the dashboard. Filters are the [HaGeZi Multi PRO](https://github.com/hagezi/dns-blocklists) general list plus the HaGeZi TIF threat feed. The web UI/API binds on `0.0.0.0` but its port stays off the LAN (tailnet-only) and runs with no credentials. `statistics` is on, so `GET /control/stats` serves the JSON that glance's native DNS widget reads (see [Glance widgets](#glance-widgets)). No `customDNS.mapping` is configured: public hostnames resolve to the Cloudflare edge, so LAN devices reach services through the outbound tunnel with no hairpin NAT required. If LAN-direct paths are ever wanted, add a rewrite fed by `config.net.addrOf "ed"`.
- **Unbound** - local recursive resolver with DNSSEC; AdGuard's primary upstream, so LAN queries resolve locally and stay off the wire.
- **Cloudflare DoH** - AdGuard `fallback_dns`: queries go to Unbound first, and only hit `one.one.one.one` when Unbound doesn't respond.
- **Prometheus + Grafana** - metrics collection and dashboards, the node exporter and Loki dashboards provisioned by the `observability` bundle. Unbound exports metrics through the letsencrypt `prometheus-unbound-exporter` feature, scraped over the tailnet (job `unbound`) and plotted on the `grafana-dashboards-unbound` dashboard. AdGuard has no native Prometheus endpoint, so only Unbound is charted for DNS. Postgres metrics come from `services.prometheus.exporters.postgres`, scraped on loopback and plotted on the provisioned Postgres dashboard.

`features/blocky.nix` is the previous resolver, kept in the tree but no longer part of the `dns` bundle.

## Glance widgets

Glance's page layout is generated from `serviceRegistry` (see [Categories](#categories)) plus a far-left column contributed by feature modules through the `glance.extraWidgets` hook (`features/glance-widgets.nix` defines the option; `dns` and `servers` stack in that narrow column):

- **DNS** (`features/glance-dns-stats.nix`) - glance's native `dns-stats` widget in `adguard` mode, reading `GET /control/stats` from the AdGuard Home on ed over the tailnet. It only appears when an `adguard` service is registered.
- **Servers** (`features/glance-server-stats.nix`) - glance's native `server-stats` widget. The stack host reads itself with the `local` probe; every other host in `observability.scrapeTargets` is read through its glance agent. The agent (`features/glance-agent.nix`, part of the `observability-agent` bundle) exposes CPU / memory / disk as JSON on `ports.glanceAgent`, tailnet-only with no token.

Ports and scrape targets come from the port registry and `net`, not from this doc.
