# Nixpkgs Channels

## Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Base Channels by Host](#base-channels-by-host)
- [Using the Alternate Channel](#using-the-alternate-channel)
- [Overriding a Host Base](#overriding-a-host-base)
- [Updating](#updating)
- [Gotchas](#gotchas)

---

## Overview

The flake pulls from two nixpkgs channels instead of one:

- `nixpkgs-stable` (`nixos-26.05`): the calm box. Conservative package
  versions, security backports only. Used where surprises hurt.
- `nixpkgs-unstable` (`nixos-unstable`): the rolling box. New releases land
  as they happen. Used where freshness wins.

Every host builds from exactly one base channel. All hosts can still reach
into the other channel for individual packages via `pkgs.stable` /
`pkgs.unstable`, without changing the base.

## How It Works

Policy lives in `modules/flake/nixpkgs.nix` (the bridge is `overlayModule`).
In short:

- Each input declares which channel it follows via `inputs.<x>.inputs.nixpkgs.follows`.
- Hosts carry a `role` option (`client` / `server`) and an optional `nixpkgs`
  override, see `modules/flake/nixosConfigurations.nix`.
- The overlay exposes both channel sets on every host. The host's base channel
  is `prev` (its own package set); the other channel is imported fresh:
  `pkgs.stable` and `pkgs.unstable`.
- An assertion in `nixpkgs.nix` fails evaluation if a `server` resolves to
  anything but `stable`.

## Base Channels by Host

| host | role | base (`pkgs.foo`) | same as | escape hatch |
|---|---|---|---|---|
| jet, ed | server | stable | `pkgs.stable.foo` | `pkgs.unstable.foo` |
| spike, faye, ein | client | unstable | `pkgs.unstable.foo` | `pkgs.stable.foo` |
| ein (macOS) | - | unstable | `pkgs.unstable.foo` | `pkgs.stable.foo` |

On the base channel the two spellings are the same object: `pkgs.blocky`
equals `pkgs.stable.blocky` on a server. Reaching across channels is the only
reason to write one of these explicitly.

## Using the Alternate Channel

Plain `pkgs.foo` always resolves from the host's base channel. Use the
alternate only when the base version is wrong for the job.

Real example: nushell integration asserts fzf >= 0.73, but stable ships 0.72.
`modules/features/fzf.nix` forces the newer one on every host:

```nix
programs.fzf = {
  enable = true;
  # nushell integration asserts fzf >= 0.73 (stable ships 0.72).
  package = pkgs.unstable.fzf;
};
```

On a client this is a no-op (`pkgs.unstable.fzf` is the base anyway); on a
server it pulls exactly one package from unstable and keeps everything else
stable.

The reverse also works: on a client, `pkgs.stable.awscli` (or whatever) pins
one package to the conservative branch.

## Overriding a Host Base

The default base comes from `role`. To force a different base for one host,
set the `nixpkgs` option in its variables file:

```nix
_: {
  configurations.nixos.jet = {
    module = { ... };
    role = "server";
    nixpkgs = "unstable"; # override (fails the assertion: servers must be stable)
  };
}
```

Note the assertion: `server` role + `unstable` base = eval error. Per-host
overrides are mainly useful for `client` machines, or as a one-line escape
hatch if a server needs to track unstable temporarily (flip it back to
`null` to return to role default).

## Updating

Both channels move independently. Update only the one you intend:

```bash
nix flake update nixpkgs-stable    # servers + stable-following inputs
nix flake update nixpkgs-unstable  # clients + home-manager + desktop inputs
nix flake update                   # both
```

After updating, inspect `git diff flake.lock` and confirm only the intended
channel's revisions moved. Then run `nix flake check`.

## Gotchas

- Followees stay wherever `flake.nix` points them. `home-manager` and other
  desktop inputs deliberately track `nixpkgs-unstable` even on servers, so
  server Home Manager code runs newer than its nixpkgs. The eval warns; this
  is accepted.
- A service module captures its package from the base channel at eval time.
  Replacing `pkgs.blocky` with `pkgs.unstable.blocky` does not swap the module
  or its option schema. Watch version-sensitive services (blocky settings
  schema) when stable lags unstable.
- Alternate-channel imports are lazy. They only cost evaluation when a package
  under `pkgs.stable` / `pkgs.unstable` is actually forced.
- Darwin hosts are always base `unstable`; there is no `role` on macOS.

## See Also

- [Deploying: Updating Nixpkgs](deploying.md#updating-nixpkgs) for the switch
  workflow
- [Flake Inputs](flake-inputs.md) for input follows and pinning