# Deploying

## Contents

- [NixOS Hosts](#nixos-hosts)
- [Darwin Hosts](#darwin-hosts)
- [Verification](#verification)
- [Fresh Install (nixos-anywhere)](#fresh-install-nixos-anywhere)
- [Building the Ed SD Image](#building-the-ed-sd-image)
- [Dev Shell](#dev-shell)

---

## NixOS Hosts

`nh os switch` and `nh os test` are provided by the `nh` package. `programs.nh.flake` sets `NH_FLAKE` to the repo path, so no flake path or hostname is needed when targeting the current host.

```bash
# Rebuild the current host
nh os switch

# Test without making it the boot default
nh os test

# Rebuild a specific host
nh os switch -H faye

# Rebuild a remote host
nh os switch -H jet --target-host arturo@jet --build-host arturo@jet

# Rebuild a NixOS host from a macOS machine (mac can't build Linux, so build on the target)
nh os switch -H faye --build-host arturo@faye --target-host arturo@faye
```

`nh` self-elevates with sudo and asks for the password itself, so no `--sudo` flags are needed.

Direct nixos-rebuild invocations also work if needed:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

### Updating Nixpkgs

Two channels feed this flake (`nixpkgs-stable`, `nixpkgs-unstable`); hosts pick a base channel by role. Update per channel:

```bash
nix flake update nixpkgs-stable    # servers (jet, ed) + stable-following inputs
nix flake update nixpkgs-unstable  # clients + home-manager + desktop inputs
nix flake update                   # both
```

Afterwards: `git diff flake.lock` (only the intended channel's revs moved) plus `nix flake check`.

Design, per-package escapes, and gotchas: [Nixpkgs Channels](nixpkgs-channels.md).

---

## Fleet Deploy (deploy-rs)

Both homelab servers (ed, jet) update with one command. Builder is **jet** (it
binfmt-builds ed's aarch64 closure). Launchers forward aarch64 builds to jet
over ssh-ng via the `remote-builder` feature (`remote-builder.host = "jet"`);
spike keeps its own binfmt as a fallback builder. Any client with
`remote-builder` set can run the fleet deploy.

```bash
nix run .#deploy-servers  # build + deploy ed, then jet
```

Semantics: ed deploys first, then jet. Failure aborts the run and rolls back
any node already deployed, so the fleet never ends up mixed. Troubleshoot a
single server:

```bash
nix run .#deploy -- .#jet                            # just jet
nix run .#deploy -- --rollback .#ed                  # roll ed back manually
```

deploy-rs connects as root over ssh (repo root key is on every NixOS host);
per-node `autoRollback` and `magicRollback` cover activation failures and
unreachable nodes. Each node inherits its host's base nixpkgs channel.

---

## Darwin Hosts

```bash
nh darwin switch -H ein
```

---

## Verification

### Check all modules evaluate before committing

```bash
nix flake check
```

### Verify all machines build from Mac

```bash
# Darwin - fully builds locally
nix build .#darwinConfigurations.ein.system

# NixOS - evaluate only (can't build Linux on Mac without a remote builder)
nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel.drvPath
```

---

## Fresh Install (nixos-anywhere)

See the comment at the top of the host's `disko.nix` for the exact command. General form:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhostname \
  --target-host nixos@<ip> \
  --generate-hardware-config nixos-facter ./modules/hosts/nixos/myhostname/facter.json
```

This SSHs to the target, generates `facter.json` (hardware detection), partitions the disk with disko, and installs NixOS. After that, commit `facter.json`, create a `facter.nix`, and remove `hardware.nix`. Once booted, fetch your config files with `chezmoi init --apply`, see [Chezmoi](chezmoi.md).

### Replacing hardware.nix with nixos-facter

On a running machine:
```bash
sudo nix run nixpkgs#nixos-facter -- -o facter.json
# copy facter.json to modules/hosts/nixos/<hostname>/facter.json
```

Create `modules/hosts/nixos/<hostname>/facter.nix`:
```nix
_: {
  configurations.nixos.<hostname>.module = {
    hardware.facter.reportPath = ./facter.json;
  };
}
```

Delete `hardware.nix`. The `hardware.facter` NixOS module reads the JSON and configures kernel modules, firmware, and CPU microcode automatically.

---

## Building the Ed SD Image

```bash
nix build .#images.ed
```

Flash the resulting image to an SD card and boot the Pi.

---

## Dev Shell

```bash
nix develop
```

Provides: `age`, `git`, `neovim`, `nixd`, `sops`. Pre-commit hooks (alejandra, statix, deadnix) are installed automatically.
