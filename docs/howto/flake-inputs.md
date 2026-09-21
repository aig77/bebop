# Flake Inputs

## Contents

- [Updating Inputs](#updating-inputs)
- [Adding a New Input](#adding-a-new-input)
- [Pinning an Input to nixpkgs](#pinning-an-input-to-nixpkgs)

---

## Updating Inputs

```bash
nix flake update             # update all inputs
nix flake update <name>      # update one specific input
```

This repo feeds from two nixpkgs channels: `nixpkgs-stable` and
`nixpkgs-unstable`. Update them per channel:

```bash
nix flake update nixpkgs-stable
nix flake update nixpkgs-unstable
```

See [Nixpkgs Channels](nixpkgs-channels.md#updating) for which channel to
update and why.

After updating, run `nix flake check` to catch any compatibility issues before committing.

---

## Adding a New Input

All inputs are declared in `flake.nix`. Add the new input to the `inputs` attrset:

```nix
inputs = {
  # ...existing inputs...
  mynewpackage = {
    url = "github:someorg/mynewpackage";
    inputs.nixpkgs.follows = "nixpkgs-unstable";  # pick a nixpkgs channel
  };
};
```

Inputs are available in flake-parts modules via the outer `inputs` argument:

```nix
{inputs, ...}: {
  flake.modules.nixos.myfeature = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.mynewpackage.packages.${pkgs.system}.default
    ];
  };
}
```

---

## Pinning an Input to nixpkgs

Inputs that accept nixpkgs should follow this repo's nixpkgs to avoid duplicate versions in the closure. Pick the channel that matches the input's host role: `"nixpkgs-stable"` for server-oriented inputs, `"nixpkgs-unstable"` for client/desktop inputs:

```nix
inputs.mynewpackage.inputs.nixpkgs.follows = "nixpkgs-unstable";
```

This is already done for most inputs in `flake.nix`. Inputs that don't take nixpkgs don't need this.

---

## Common Issues

**New input not visible in modules:** Check that the module's outer function takes `inputs` as an argument. import-tree and flake-parts pass it down automatically.

**`error: infinite recursion` with darwin inputs:** nix-darwin has a known issue with `inputs.self` in `specialArgs`. This is handled in `modules/flake/darwinConfigurations.nix` by removing `self` from `specialArgs`.
