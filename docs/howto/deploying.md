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

```bash
sudo nixos-rebuild switch --flake .#faye
sudo nixos-rebuild switch --flake .#ed
```

---

## Darwin Hosts

```bash
darwin-rebuild switch --flake .#ein
darwin-rebuild switch --flake .#spike
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
nix build .#darwinConfigurations.spike.system

# NixOS - evaluate only (can't build Linux on Mac without a remote builder)
nix eval .#nixosConfigurations.faye.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.ed.config.system.build.toplevel.drvPath
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

This SSHs to the target, generates `facter.json` (hardware detection), partitions the disk with disko, and installs NixOS. After that, commit `facter.json`, create a `facter.nix`, and remove `hardware.nix`.

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
