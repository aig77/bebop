# Flake Inputs

## Contents

- [Updating Inputs](#updating-inputs)
- [Adding a New Input](#adding-a-new-input)
- [Pinning an Input to nixpkgs](#pinning-an-input-to-nixpkgs)

---

## Updating Inputs

```bash
nix flake update          # update all inputs
nix flake update nixpkgs  # update one specific input
```

After updating, run `nix flake check` to catch any compatibility issues before committing.

---

## Adding a New Input

All inputs are declared in `flake.nix`. Add the new input to the `inputs` attrset:

```nix
inputs = {
  # ...existing inputs...
  mynewpackage = {
    url = "github:someorg/mynewpackage";
    inputs.nixpkgs.follows = "nixpkgs";  # if it takes nixpkgs
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

Inputs that accept nixpkgs should follow this repo's nixpkgs to avoid duplicate versions in the closure:

```nix
inputs.mynewpackage.inputs.nixpkgs.follows = "nixpkgs";
```

This is already done for most inputs in `flake.nix`. Inputs that don't take nixpkgs don't need this.

---

## Common Issues

**New input not visible in modules:** Check that the module's outer function takes `inputs` as an argument. import-tree and flake-parts pass it down automatically.

**`error: infinite recursion` with darwin inputs:** nix-darwin has a known issue with `inputs.self` in `specialArgs`. This is handled in `modules/flake/darwinConfigurations.nix` by removing `self` from `specialArgs`.
