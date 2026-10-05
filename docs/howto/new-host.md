# Adding a Host

## Contents

- [Adding a NixOS Host](#adding-a-nixos-host)
- [Adding a Darwin Host](#adding-a-darwin-host)

---

## Adding a NixOS Host

### 1. Create the host directory

```text
modules/hosts/nixos/myhostname/
├── imports.nix
├── variables.nix
├── ports.nix           # this host's port registry (server hosts)
├── hardware.nix        # or facter.nix + facter.json (preferred)
├── disko.nix
├── home.nix
└── state-version.nix
```

### 2. `imports.nix`

```nix
{config, ...}: {
  configurations.nixos.myhostname.module = {
    imports = with config.flake.modules.nixos; [
      desktop hyprland amdgpu
    ];
  };
}
```

### 3. `variables.nix`

```nix
_: {
  configurations.nixos.myhostname.module = {
    var = {
      username = "arturo";
      hostname = "myhostname";
      shell    = "zsh";
      # Hosts are auto-discovered from the configurations.nixos registry, so
      # nothing network-related goes here.
    };
  };
}
```

### 4. `state-version.nix`

```nix
_: {
  configurations.nixos.myhostname.module = {
    system.stateVersion = "25.05";
  };
}
```

### 5. `hardware.nix`

Copy from spike and adjust kernel modules, CPU microcode, and hostPlatform. Or use nixos-facter (preferred):

```nix
_: {
  configurations.nixos.myhostname.module = {
    hardware.facter.reportPath = ./facter.json;
  };
}
```

### 6. `disko.nix`

Copy from spike and adjust the disk device and layout. Include a comment with the nixos-anywhere install command.

### 7. `home.nix`

```nix
_: {
  configurations.nixos.myhostname.module = {config, pkgs, ...}: {
    home-manager.users.${config.var.username} = {
      home.packages = with pkgs; [some-package];
    };
  };
}
```

### 8. Register and verify

```bash
git add modules/hosts/nixos/myhostname/
nix eval .#nixosConfigurations.myhostname.config.system.build.toplevel.drvPath
```


### Fresh install via nixos-anywhere

[Reference](deploying#fresh-install-nixos-anywhere)

---

## Adding a Darwin Host

### 1. Create the host directory

```text
modules/hosts/darwin/mymac/
├── imports.nix
├── variables.nix
├── hostname.nix
├── homebrew.nix
└── home.nix
```

### 2. `imports.nix`

```nix
{config, ...}: {
  configurations.darwin.mymac.module = {
    imports = with config.flake.modules.darwin; [base];
  };
}
```

### 3. `variables.nix`

```nix
_: {
  configurations.darwin.mymac.module = {
    var = {
      username = "arturo";
      hostname = "mymac";
      shell    = "zsh";
    };
  };
}
```

### 4. `hostname.nix`

```nix
_: {
  configurations.darwin.mymac.module = {
    networking = {
      hostName     = "mymac";
      computerName = "mymac";
    };
  };
}
```

### 5. `home.nix`

```nix
_: {
  configurations.darwin.mymac.module = {config, pkgs, ...}: {
    home-manager.users.${config.var.username} = {
      home = {
        homeDirectory = "/Users/${config.var.username}";
        stateVersion  = "24.11";
        packages = with pkgs; [some-package];
      };
    };
  };
}
```

### 6. Register and verify

```bash
git add modules/hosts/darwin/mymac/
nix build .#darwinConfigurations.mymac.system
```
