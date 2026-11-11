# Zen Session Sync

`zen-sync` keeps Zen Browser spaces, pinned tabs, and the open session in sync
between spike and ein through an encrypted Cloudflare R2 bucket.

Nix owns the reproducible browser setup: policies, settings, extensions, mods,
search engines, and theme. R2 owns the live session: spaces, pins, open tabs,
containers, and the active workspace.

The feature is Home Manager only. Importing `zen-sync` from `hm.gui` is the
opt-in; there is no NixOS module to add.

## Contents

- [How It Works](#how-it-works)
- [R2 Setup](#r2-setup)
- [Secrets](#secrets)
- [Build and Seed](#build-and-seed)
- [Automatic Behavior](#automatic-behavior)
- [Manual Controls](#manual-controls)
- [Keybind](#keybind)
- [Troubleshooting](#troubleshooting)
- [Caveats](#caveats)

---

## How It Works

The `zen-sync-run` launcher wraps the real Zen binary:

1. If Zen is already running, the launch is forwarded to the existing instance.
2. Before starting Zen, it checks the remote metadata.
3. If the remote changed and the local session is clean, it pulls the remote.
4. If the remote changed and the local session has unsynced changes, it merges.
5. After Zen exits, it merges if the other machine pushed while you were
   browsing, then pushes the local session.
6. If the network fails, it logs and leaves the state for the retry timer.

State lives in `~/.local/state/zen-sync/`:

```text
last-pushed-hash   hash of zen-sessions.jsonlz4 after the last push or pull
last-remote-ts     timestamp of the last remote metadata we consumed
request            queued pull or merge for the next launch
backups/           local snapshots taken before sync operations
log                launcher and zen-sync output
```

Local snapshots are pruned to the last 20.

## R2 Setup

Create a bucket in the Cloudflare account used for backups. Do not reuse the
restic bucket or its token.

1. Create a bucket named `bebop-zen-sync`.
2. Create an R2 API token with Object Read and Write, limited to that bucket.
3. Note the account ID, access key ID, secret access key, and bucket name.
4. Optional: enable object versioning with a lifecycle rule that expires old
   versions after 30 days. The script overwrites the same two objects.
5. Generate one age identity:

   ```bash
   age-keygen -o /tmp/zen-sync-age.key
   ```

   Keep a copy of the identity in Bitwarden. If it is lost, the remote archive
   cannot be decrypted.

The bucket should contain `session.tar.gz.age` and `meta.json.age` after the
first push.

## Secrets

Edit the secrets file and add the keys under `zen-sync`:

```bash
sops modules/aspects/secrets/secrets.yaml
```

The structure is:

```yaml
zen-sync:
    r2-account-id: <account id>
    r2-access-key: <access key id>
    r2-secret-key: <secret access key>
    r2-bucket: bebop-zen-sync
    age-key: |
        # created: ...
        # public key: age1...
        AGE-SECRET-KEY-...
```

The values must match the secrets declared in
`modules/features/zen-sync/default.nix`. Home Manager's sops-nix module decrypts
them at user activation. The rendered files live under
`~/.config/sops-nix/secrets/`, and the generated launcher config is written
directly to `~/.config/zen-sync/config` with mode `0400`.

Home Manager sops needs a user-readable age key at:

```text
~/.config/sops/age/keys.txt
```

That key must be a recipient in `.sops.yaml`. On spike it already exists and
matches the spike recipient. On ein, make sure the equivalent key exists and
matches the ein recipient. If the key is missing, copy the host key:

```bash
sudo install -m 600 -o "$USER" -g "$(id -gn)" \
  /etc/sops/age/keys.txt ~/.config/sops/age/keys.txt
```

The Home Manager activation also enforces mode `0600` on that key.

## Build and Seed

Add the secrets before rebuilding. Home Manager sops validates the sops file at
build time, so a switch before the `zen-sync` keys exist fails with
`the key 'zen-sync' cannot be found`.

Zen must be closed while a sync runs.

```bash
nh os switch
```

On the first machine, seed the bucket:

```bash
zen-sync push
```

Then switch the second machine and pull:

```bash
zen-sync pull
```

After the first manual seed, the launcher handles the normal flow.

## Automatic Behavior

The automatic path is:

- open: pull when the local session is clean, merge when it is dirty
- close: merge if the remote moved while you were browsing, then push
- retry: a systemd user timer runs `zen-sync-run --flush` every 15 minutes when
  Zen is not running

A pull is destructive by design. It replaces the local session with the remote
one, which is how space deletions and renames propagate. If the local session
has unsynced changes, the launcher merges instead.

## Manual Controls

Use the fuzzel menu:

```bash
zen-sync-menu
```

It offers status, push, pull, merge, and queued pull or merge for the next
start. The pull and merge actions restart Zen because the session files cannot
be replaced safely while Zen is running.

Direct commands are also available when Zen is closed:

```bash
zen-sync status
zen-sync push
zen-sync pull
zen-sync merge
zen-sync-run --sync-now pull
zen-sync-run --flush
```

## Keybind

`Super+Shift+B` opens the menu.

- Niri: `modules/features/niri.nix`
- Mango: `modules/features/mango.nix`
- Hyprland: the binds live outside this repo, in
  `~/.config/hypr/config/binds.lua`. Add:

  ```lua
  bind(ms("B"), exec("zen-sync-menu"), d("Zen Sync"))
  ```

  The `ms` helper is already defined in that file. If the Hyprland config is
  migrated into this repo later, move this bind with it.

## Troubleshooting

Check the log first:

```bash
tail -n 50 ~/.local/state/zen-sync/log
```

Common cases:

- `zen-sync status` reports a connection error: the rendered config or the age
  key is missing. Rebuild, then confirm `~/.config/zen-sync/config` exists and
  Home Manager sops decrypted the keys under `~/.config/sops-nix/secrets/`.
- The build fails with `the key 'zen-sync' cannot be found`: the `zen-sync`
  block has not been added to `modules/aspects/secrets/secrets.yaml` yet.
- Home Manager activation cannot decrypt the secrets file:
  `~/.config/sops/age/keys.txt` is missing or is not a recipient in
  `.sops.yaml`.
- `zen-sync pull` fails with a decrypt error: the age identity in sops does not
  match the one used to push. Both machines must share the same identity.
- The menu queues an action but nothing happens: the request is applied by the
  next `zen-sync-run` launch. Restart Zen through the desktop entry or the
  `zen` command.
- A rebuild says the session was skipped: Zen was open. Close Zen and rebuild
  again. This should not happen after the declarative pins and spaces were
  removed.
- Versions differ between machines: both machines must be rebuilt to the same
  flake revision and Zen version before relying on the sync.

Reset the local sync state without touching the session:

```bash
rm -f ~/.local/state/zen-sync/last-pushed-hash
rm -f ~/.local/state/zen-sync/last-remote-ts
```

The next launch will treat the local session as dirty and merge rather than
pull.

## Caveats

- Merge is additive. Space deletions, renames, icon changes, and tab deletions
  only propagate through pull. The launcher pulls when the local session is
  clean.
- Concurrent use is approximate. If both machines are used before either
  pushes, the close-time merge preserves new tabs but can bring back a space
  deleted on the other machine.
- R2 overwrites the same two objects. Keep local snapshots and optionally
  enable bucket versioning.
- One profile is synced: `~/.config/zen/default`. Separate profiles per
  activity would need separate buckets and configs.
- Do not declare pins, spaces, or containers in Nix while this feature is
  enabled. The zen-browser module would rewrite the same session file that
  zen-sync owns.
- `prefs.js` is synced, so the active workspace follows the last machine that
  pushed. Declarative settings stay in `user.js` and win on startup.
