# Troubleshooting

## Contents

- [New .nix File Not Picked Up](#new-nix-file-not-picked-up)
- [attribute 'X' missing in Home Manager Module](#attribute-x-missing-in-home-manager-module)
- [Downloaded Binary Will Not Run](#downloaded-binary-will-not-run)
- [statix Warning: Replace {...}: with _:](#statix-warning-replace--with-_)
- [deadnix Warning: Unused Variable](#deadnix-warning-unused-variable)
- [SOPS Secrets Not Decrypting](#sops-secrets-not-decrypting)
- [RPi Build Fails with seccomp Error](#rpi-build-fails-with-seccomp-error)
- [SOPS Template Permission Denied](#sops-template-permission-denied)

---

## New .nix File Not Picked Up

**Symptom:** A newly created `.nix` file has no effect, or Nix evaluation throws `attribute 'myprofile' missing` even though the file exists.

**Cause:** `import-tree` uses `git ls-files` to enumerate files. Untracked files are invisible to Nix evaluation.

**Fix:**

```bash
git add modules/features/myfeature.nix
```

The file does not need to be committed - staged is sufficient. After `git add`, re-run `nix flake check` or `nh os switch`.

---

## attribute 'X' missing in Home Manager Module

**Symptom:** Evaluation error such as `error: attribute 'sops' missing` inside a Home Manager module.

**Cause:** Inside a HM module, `config` refers to the Home Manager configuration, not the NixOS configuration. Accessing `config.sops` or `config.var` from within HM fails because those options live on the NixOS module system.

**Fix:** Use `osConfig` to access NixOS options from within a HM module:

```nix
# Wrong - config here is the HM config
config.sops.secrets.my-secret.path
config.var.hostname

# Correct - osConfig reaches the NixOS config
osConfig.sops.secrets.my-secret.path
osConfig.var.hostname
```

`config` inside HM is for HM options only:

```nix
config.programs.zsh.enable   # HM option - correct
```

---

## Downloaded Binary Will Not Run

**Symptom:** A binary an app downloaded for itself, or an upstream release tarball, fails to launch. Either a bare `No such file or directory` even though the file is there, or:

```text
error while loading shared libraries: libfoo.so.1: cannot open shared object file
```

**Cause:** NixOS has no `/lib64/ld-linux-x86-64.so.2`. Binaries built for normal distributions hardcode that interpreter path, so the kernel cannot start them. [nix-ld](https://github.com/nix-community/nix-ld) shims the loader path so they work.

`nix-ld` is enabled on the `desktop` bundle, which covers `spike`, `faye`, and `ein`. Servers and the HTPC do not have it, since they run no foreign binaries.

**Fix for a missing library:** the error names the `.so` you need. Find which package provides it, then add that one package to the list in `modules/features/nix-ld.nix`:

```bash
nix run github:nix-community/nix-index-database -- lib/libfoo.so.1 --top-level
```

Do not paste a prebuilt list. The 120-entry list at [wiki.nixos.org/wiki/Nix-ld](https://wiki.nixos.org/wiki/Nix-ld) is a stopgap for running Steam, Unity, AppImages and SDL titles, it costs a multi-gigabyte buildEnv in every login shell, and it carries entries that no longer exist in nixpkgs. `modules/features/nix-ld.nix` documents this.

**Not the same problem:** if the binary runs but the app cannot find it by name, that is a `PATH` problem, not a loader problem. `nix-ld` does not affect lookup. See `home.sessionPath` in Home Manager.

---

## statix Warning: Replace {...}: with _:

**Symptom:** `statix` lint warns about a module's outer function using `{...}:` when no arguments are used.

**Cause:** When the outer flake-parts function takes no named arguments, `{...}:` is an antipattern. `statix` flags it.

**Fix:** Replace `{...}:` with `_:`:

```nix
# Before - triggers statix warning
{...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
  };
}

# After - correct
_: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
  };
}
```

Use `_:` only when the outer function truly takes no arguments. If the module needs `config`, `inputs`, or `lib` from flake-parts, keep the named argument.

---

## deadnix Warning: Unused Variable

**Symptom:** `deadnix` warns about an unused binding in a function argument pattern.

**Cause:** A variable is listed in a function argument pattern but never referenced in the body.

**Fix:** Remove unused arguments from the pattern, or replace them with `...` if other arguments in the pattern are still needed:

```nix
# Before - lib is declared but never used
{pkgs, lib, config, ...}: {
  environment.systemPackages = [pkgs.something];
}

# After - remove the unused binding
{pkgs, config, ...}: {
  environment.systemPackages = [pkgs.something];
}
```

If no named arguments are used at all in the inner module function, replace the pattern with `_:`:

```nix
_: {
  services.something.enable = true;
}
```

---

## SOPS Secrets Not Decrypting

**Symptom:** Activation fails with a sops-nix error, or secrets are missing at `/run/secrets/`.

**Possible causes and fixes:**

**1. Age key not present at expected path**

For regular hosts (desktop, laptop), the age key must exist at:

```text
~/.config/sops/age/keys.txt
```

For server hosts (machines using `nixos.server`), the key path is overridden to:

```text
/etc/sops/age/keys.txt
```

This distinction is set in `modules/bundles/machines.nix` via `sops.age.keyFile = lib.mkForce "/etc/sops/age/keys.txt"`. Ensure the key file exists at the correct path for the machine type.

**2. Machine's public key not in `.sops.yaml`**

The machine's age public key must be listed in `.sops.yaml` and `secrets.yaml` must be re-encrypted with that key. See [Managing Age Keys](age-keys.md) for the procedure.

**3. Wrong file permissions**

sops-nix requires the key file to be readable only by its owner (`0600`). Check:

```bash
ls -la ~/.config/sops/age/keys.txt
# -rw------- 1 arturo arturo ...
```

---

## RPi Build Fails with seccomp Error

**Symptom:** Building on or for an aarch64 Raspberry Pi fails with a `seccomp` or `syscall filter` error during Nix evaluation or building.

**Cause:** The Nix sandbox uses seccomp syscall filtering, which some aarch64 kernels (particularly the RPi kernel) do not fully support.

**Fix:** Set `nix.settings.filter-syscalls = false` in the host's `imports.nix`. This is already set for `ed`:

```nix
# modules/hosts/nixos/ed/imports.nix
configurations.nixos.ed.module = {
  imports = with config.flake.modules.nixos; [base server tailscale dns];
  nixpkgs.hostPlatform = "aarch64-linux";
  nix.settings.filter-syscalls = false;
};
```

Apply the same setting to any new aarch64 host that encounters this error.

---

## SOPS Template Permission Denied

**Symptom:** A systemd service using a `sops.templates` file fails with `Permission denied` when reading the rendered file.

**Cause:** sops-nix renders templates with mode `0400` (owner-readable only) by default. Services running as `DynamicUser` or a different system user cannot read the file.

**Fix:** Set `mode = "0444"` on the template so it is world-readable:

```nix
sops.templates."myapp-config.json" = {
  content = builtins.toJSON {
    api_key = config.sops.placeholder."my-secret";
  };
  mode = "0444";
};
```

Use `0444` only when the file contains no material that should be kept from other local processes. For secrets that must stay restricted, configure the service to run as the user that owns the secret instead.
