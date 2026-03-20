# How-To Guide

## Rebuilding

### NixOS
```bash
sudo nixos-rebuild switch --flake .#faye
sudo nixos-rebuild switch --flake .#ed
```

### Darwin
```bash
darwin-rebuild switch --flake .#ein
darwin-rebuild switch --flake .#spike
```

### Check everything evaluates before committing
```bash
nix flake check
```

### Verify all machines build (run from Mac)
```bash
# Darwin (fully builds locally)
nix build .#darwinConfigurations.ein.system
nix build .#darwinConfigurations.spike.system

# NixOS (evaluate only — can't build Linux on Mac without a remote builder)
nix eval .#nixosConfigurations.faye.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.ed.config.system.build.toplevel.drvPath
```

---

## Adding a New Feature Module

A feature module is a flake-parts module that contributes to one or more named profiles. Create a `.nix` file anywhere in `modules/` (it will be auto-imported), then `git add` it.

### NixOS system-level feature

```nix
# modules/myfeature/default.nix
_: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [pkgs.something];
    services.something.enable = true;
  };
}
```

Then add `myfeature` to the host's `imports.nix`:
```nix
# modules/hosts/nixos/faye/imports.nix
{config, ...}: {
  configurations.nixos.faye.module = {
    imports = with config.flake.modules.nixos; [
      base desktop hyprland amdgpu gaming docker tailscale
      myfeature  # add here
    ];
  };
}
```

### Home Manager feature

```nix
# modules/myapp/default.nix
_: {
  flake.modules.homeManager.gui = {pkgs, ...}: {
    programs.myapp = {
      enable = true;
    };
  };
}
```

Contributing to an existing profile (`base`, `gui`, etc.) means every host that already uses that profile gets it automatically — no host changes needed.

If it should be opt-in, create a new profile name and wire it in `home-manager/nixos.nix`:
```nix
myfeature = _: {
  home-manager.users.${username}.imports = [hm.myfeature];
};
```

### Feature that spans both system and HM

This is the dendritic pattern's strength. One directory, one concept:

```nix
# modules/myapp/nixos.nix
_: {
  flake.modules.nixos.myapp = {pkgs, ...}: {
    services.myapp.enable = true;           # system service
    environment.systemPackages = [pkgs.myapp];
  };
}
```

```nix
# modules/myapp/home.nix
_: {
  flake.modules.homeManager.myapp = {pkgs, config, ...}: {
    programs.myapp = {                      # user config
      enable = true;
      settings = { ... };
    };
  };
}
```

Then add both to `home-manager/nixos.nix`:
```nix
myapp = _: {
  home-manager.users.${username}.imports = [hm.myapp];
};
```

And to any host's `imports.nix`:
```nix
imports = with config.flake.modules.nixos; [base desktop myapp];
```

---

## Adding a New NixOS Host

1. Create the host directory:
```
modules/hosts/nixos/myhostname/
├── imports.nix
├── variables.nix
├── hardware.nix   (or facter.nix + facter.json)
├── disko.nix
├── home.nix
└── state-version.nix
```

2. `imports.nix` — choose profiles:
```nix
{config, ...}: {
  configurations.nixos.myhostname.module = {
    imports = with config.flake.modules.nixos; [
      base desktop hyprland amdgpu
    ];
  };
}
```

3. `variables.nix` — set vars:
```nix
_: {
  configurations.nixos.myhostname.module = {
    var = {
      username = "arturo";
      hostname = "myhostname";
      shell = "zsh";
      location = "Miami";
    };
  };
}
```

4. `state-version.nix`:
```nix
_: {
  configurations.nixos.myhostname.module = {
    system.stateVersion = "25.05";
  };
}
```

5. `hardware.nix` — copy from faye and adjust, or use nixos-facter (see below).

6. `disko.nix` — copy from faye and adjust disk device/layout. Include the nixos-anywhere install comment.

7. `git add modules/hosts/nixos/myhostname/` — required for import-tree to see the files.

8. Verify: `nix eval .#nixosConfigurations.myhostname.config.system.build.toplevel.drvPath`

### Fresh install with nixos-anywhere

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhostname \
  --target-host nixos@<ip> \
  --generate-hardware-config nixos-facter ./modules/hosts/nixos/myhostname/facter.json
```

This: SSHs to the target, generates `facter.json` (hardware detection), partitions disk with disko, installs NixOS. After it completes, commit `facter.json`, add a `facter.nix`, and remove `hardware.nix`.

### Migrating to nixos-facter (replacing hardware.nix)

On the running machine:
```bash
sudo nix run nixpkgs#nixos-facter -- -o facter.json
# copy facter.json to modules/hosts/nixos/faye/facter.json
```

Create `modules/hosts/nixos/faye/facter.nix`:
```nix
_: {
  configurations.nixos.faye.module = {
    hardware.facter.reportPath = ./facter.json;
  };
}
```

Delete `modules/hosts/nixos/faye/hardware.nix`. The `hardware.facter` NixOS module (in nixpkgs) reads the JSON and configures kernel modules, firmware, and CPU microcode automatically.

---

## Adding a New Darwin Host

1. Create the host directory:
```
modules/hosts/darwin/mymac/
├── imports.nix
├── variables.nix
├── hostname.nix
├── homebrew.nix
└── home.nix
```

2. `imports.nix`:
```nix
{config, ...}: {
  configurations.darwin.mymac.module = {
    imports = with config.flake.modules.darwin; [base];
  };
}
```

3. `variables.nix`:
```nix
_: {
  configurations.darwin.mymac.module = {
    var = {
      username = "arturo";
      hostname = "mymac";
      shell = "zsh";
    };
  };
}
```

4. `hostname.nix`:
```nix
_: {
  configurations.darwin.mymac.module = {
    networking = {
      hostName = "mymac";
      computerName = "mymac";
    };
  };
}
```

5. `homebrew.nix` — macOS-only casks:
```nix
_: {
  configurations.darwin.mymac.module = {
    homebrew.casks = ["ghostty" "raycast"];
  };
}
```

6. `home.nix` — host-specific HM packages:
```nix
_: {
  configurations.darwin.mymac.module = {config, pkgs, ...}: {
    home-manager.users.${config.var.username} = {
      home = {
        homeDirectory = "/Users/${config.var.username}";
        stateVersion = "24.11";
        packages = with pkgs; [some-package];
      };
    };
  };
}
```

7. `git add modules/hosts/darwin/mymac/`

8. Verify: `nix build .#darwinConfigurations.mymac.system`

---

## Adding a New Secret

1. Edit the secrets file:
```bash
sops modules/secrets/secrets.yaml
```

2. Add the key under the existing YAML structure.

3. Declare it in `modules/secrets/default.nix`:
```nix
sops.secrets.my-new-secret = {};
```

4. Use it in a module. At runtime the decrypted value is available at `/run/secrets/my-new-secret`. For HM modules, reference it via `osConfig.sops.secrets.my-new-secret.path`.

For templated secrets (e.g. JSON config files), use `sops.templates`:
```nix
sops.templates."myapp-config.json" = {
  content = builtins.toJSON {
    api_key = config.sops.placeholder."my-new-secret";
  };
  mode = "0444";
};
```

---

## Adding a New Age Key (New Machine)

When adding a new machine that needs to decrypt secrets:

1. On the new machine, generate an age key:
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# prints: Public key: age1...
```

2. Add the public key to `.sops.yaml`:
```yaml
keys:
  - &newmachine age1...
creation_rules:
  - path_regex: modules/secrets/.*\.yaml$
    key_groups:
      - age:
        - *ein
        - *faye
        - *spike
        - *ed
        - *newmachine  # add here
```

3. Re-encrypt the secrets file with the new key added:
```bash
sops updatekeys modules/secrets/secrets.yaml
```

---

## Editing the Flake Inputs

All inputs are in `flake.nix`. After changing an input URL:
```bash
nix flake update          # update all inputs
nix flake update nixpkgs  # update one input
```

Inputs that follow nixpkgs are pinned via `inputs.nixpkgs.follows = "nixpkgs"` — they don't need separate update commands.

---

## Common Issues

**New file not picked up by Nix**
import-tree uses git to list files. Run `git add <file>` before `nix build` or `nix flake check`.

**`error: attribute 'X' missing` in a HM module**
If accessing a NixOS option from within HM (e.g. `sops`, `networking`), use `osConfig.X` instead of `config.X`. Regular `config` inside HM is the HM config, not NixOS.

**Darwin build fails with `home-manager option does not exist`**
`inputs.home-manager.darwinModules.home-manager` must be included in the darwin builder. It's in `modules/flake/darwinConfigurations.nix`.

**Package not available on platform**
Guard with `lib.mkIf pkgs.stdenv.isLinux { ... }` or `lib.mkIf pkgs.stdenv.isDarwin { ... }`. Example: OBS Studio is Linux-only in nixpkgs.

**`statix` warning: empty pattern**
Replace `{...}:` with `_:` when no named args are used from the function argument.

**`deadnix` warning: unused binding**
Remove unused variables from the function argument pattern (e.g. remove `config,` if `config` is never referenced in the body).
