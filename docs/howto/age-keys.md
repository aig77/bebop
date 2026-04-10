# Managing Age Keys

## Contents

- [How Keys Work](#how-keys-work)
- [Adding a New Machine](#adding-a-new-machine)
- [Rotating a Key](#rotating-a-key)

---

## How Keys Work

Each machine has its own age key pair. All four keys are listed in `.sops.yaml` and all can decrypt `modules/aspects/secrets/secrets.yaml`. This means any machine can rebuild from a fresh clone without needing keys from other machines.

Key location on each machine: `~/.config/sops/age/keys.txt`

---

## Adding a New Machine

### 1. Generate an age key on the new machine

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# prints: Public key: age1...
```

Copy the public key printed to stdout.

### 2. Add the public key to `.sops.yaml`

```yaml
keys:
  - &ein   age1...
  - &faye  age1...
  - &spike age1...
  - &ed    age1...
  - &newmachine age1...   # add here
creation_rules:
  - path_regex: modules/aspects/secrets/.*\.yaml$
    key_groups:
      - age:
        - *ein
        - *faye
        - *spike
        - *ed
        - *newmachine     # add here too
```

### 3. Re-encrypt the secrets file with the new key

```bash
sops updatekeys modules/aspects/secrets/secrets.yaml
```

Commit both `.sops.yaml` and the re-encrypted `secrets.yaml`.

---

## Rotating a Key

If a machine's private key is compromised or lost:

1. Generate a new key on the machine (`age-keygen`).
2. Update the public key in `.sops.yaml`.
3. Run `sops updatekeys modules/aspects/secrets/secrets.yaml`.
4. Commit both files.

The old key can no longer decrypt the secrets file after `updatekeys`.
