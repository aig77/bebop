# Managing Secrets

## Contents

- [Adding a Secret](#adding-a-secret)
- [Using a Secret at Runtime](#using-a-secret-at-runtime)
- [Using a Secret from Home Manager](#using-a-secret-from-home-manager)
- [Templated Secrets](#templated-secrets)

---

## Adding a Secret

### 1. Edit the secrets file

```bash
sops modules/aspects/secrets/secrets.yaml
```

Add the new key under the existing YAML structure.

### 2. Declare it in `modules/aspects/secrets/default.nix`

```nix
sops.secrets.my-new-secret = {};
```

### 3. Use it

sops-nix decrypts the value at activation time. At runtime it lives at `/run/secrets/my-new-secret`.

---

## Using a Secret at Runtime

From a NixOS module:

```nix
config.sops.secrets.my-new-secret.path
# evaluates to "/run/secrets/my-new-secret"
```

For values needed at eval time (e.g., a URL in a config file), use `sops.templates` instead. The `/run/secrets/` path is only valid at runtime.

---

## Using a Secret from Home Manager

`osConfig` accesses NixOS options from within a HM module:

```nix
osConfig.sops.secrets.my-new-secret.path
```

Do not use `config.sops.*` inside HM. `config` there is the HM config, not NixOS.

---

## Templated Secrets

For secrets that need to be rendered into a config file:

```nix
sops.templates."myapp-config.json" = {
  content = builtins.toJSON {
    api_key = config.sops.placeholder."my-new-secret";
  };
  mode = "0444";
};
```

The rendered file lives at `/run/secrets/render/myapp-config.json`. Access the path via:

```nix
config.sops.templates."myapp-config.json".path
# or from HM:
osConfig.sops.templates."myapp-config.json".path
```

The existing `weatherapi.json` template (for hyprpanel's weather widget) is an example of this.
