# Disaster recovery

This document describes how to recover the SOPS secrets and Borg repositories
after losing or replacing a host.

## Recovery model

The recovery root is a dedicated age identity stored in the online password
manager. Its public recipient is:

```text
age1mgs247pc6drcn3l8jy36ayy3km3qf9jjlej2td6f3nsfztjlys6sqpz23l
```

The private identity must never be committed to this repository, stored in a
Borg repository, or left permanently on a host. The public recipient is safe to
store in `secrets/.sops.yaml`.

The recovery chain is:

```text
Online password manager
└── SOPS recovery age private identity
    └── Encrypted files in the Nix configuration Git repository
        ├── Borg passphrases
        ├── Exported Borg repository keys
        ├── OVH S3 credentials
        └── Other host and shared secrets
```

The recovery identity is effectively a break-glass master key for every SOPS
file that includes its public recipient. Access to both the recovery identity
and the encrypted Git repository permits those files to be decrypted.

## Secret locations

| Material | Location |
| --- | --- |
| Recovery age private identity | Online password manager only |
| Recovery age public recipient | `secrets/.sops.yaml` |
| Host SSH private key | On that host; normally regenerate after loss |
| Borg 1.4 exported repository keys | `secrets/hosts/<hostname>.yaml` |
| Borg 2 exported repository key | `secrets/hosts/<hostname>.yaml` |
| Borg passphrase | `secrets/hosts/<hostname>.yaml` |
| OVH S3 credentials | `secrets/shared.yaml` |

Do not store the recovery private identity inside a SOPS file encrypted by that
identity. That would create a circular recovery path.

## Recovery-recipient rollout

The recovery recipient must be present both in `.sops.yaml` and in each
encrypted file's SOPS metadata. Adding it to `.sops.yaml` alone is not enough.

- [x] `secrets/shared.yaml`
- [x] `secrets/obojima-glyph.ttf.json`
- [x] `secrets/hosts/jay-mopo.yaml`
- [ ] `secrets/hosts/jay-framework.yaml`
- [ ] `secrets/hosts/jay-desktop.yaml`

Update each outstanding host file on the host that can currently decrypt it:

```sh
cd /etc/nixos/secrets
sops updatekeys -y "hosts/$(hostname).yaml"
```

Commit the rewrapped file, then mark it complete above.

## Test the recovery identity

Retrieve the private identity from the password manager and place it temporarily
in the per-user runtime directory, which is normally memory-backed and removed
at logout:

```sh
recovery_directory="${XDG_RUNTIME_DIR:?}/sops-recovery"
recovery_identity="$recovery_directory/identity.txt"

install -d -m 700 "$recovery_directory"
install -m 600 /dev/null "$recovery_identity"
$EDITOR "$recovery_identity"
```

Paste the complete age identity from the password manager, save it, and test a
host file:

```sh
test_home="$(mktemp -d)"
HOME="$test_home" SOPS_AGE_KEY_FILE="$recovery_identity" \
  sops decrypt /etc/nixos/secrets/hosts/jay-mopo.yaml >/dev/null
rmdir "$test_home"
```

Using an empty temporary `HOME` ensures the test does not silently fall back to
the host's normal SSH private key. Remove the temporary identity immediately:

```sh
rm -f "$recovery_identity"
rmdir "$recovery_directory"
unset recovery_identity recovery_directory
```

Perform this test after changing SOPS recipients and periodically thereafter.

## Recover a lost host

### 1. Establish the recovery environment

On a trusted replacement machine:

1. Restore access to the password manager using a recovery method that does not
   depend solely on the lost host.
2. Clone this Nix configuration repository.
3. Load the recovery age identity into the runtime directory as described
   above.
4. Verify that it decrypts `secrets/hosts/<hostname>.yaml`.

### 2. Generate a replacement host identity

Generate a new SSH key rather than restoring the lost host's operational private
key:

```sh
install -d -m 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
```

Convert its public key to an age recipient:

```sh
nix shell nixpkgs#ssh-to-age --command \
  ssh-to-age <"$HOME/.ssh/id_ed25519.pub"
```

Add the resulting public recipient to `secrets/.sops.yaml` for the replacement
host. Keep the recovery recipient in the same age key group.

Rewrap the host file using the recovery identity:

```sh
cd /etc/nixos/secrets
SOPS_AGE_KEY_FILE="$recovery_identity" \
  sops updatekeys -y "hosts/<hostname>.yaml"
```

Test decryption with the new host SSH key before removing the old recipient.

### 3. Replace external SSH authorization

Install the replacement SSH public key on both Hetzner Storage Boxes and any
other service that trusted the lost host key. Once the new key works, revoke the
old public key.

### 4. Rebuild and verify services

Follow the bootstrap and rebuild steps in `NEW_HOST_SETUP.md`, then start the
user secret service:

```sh
systemctl --user start sops-nix.service
```

Verify both backup generations:

```sh
borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" repo-info
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" repo-info
```

The repositories use repokeys, so a healthy repository normally provides its
own key. The exported keys in the host SOPS file are for recovery if the
repository's embedded key is lost or corrupted. Recovery still requires the
original Borg passphrase.

### 5. Finish the rotation

After verifying the replacement host:

1. Remove the lost host's old recipient from `secrets/.sops.yaml`.
2. Run `sops updatekeys -y` on its host secret file again.
3. Commit the recipient rotation.
4. Remove the temporary recovery identity from the runtime directory.

## Password-manager resilience

An online-only recovery design makes the password-manager account the root of
trust and an availability dependency. Keep its account-recovery details and
multi-factor recovery method independent of these hosts. Losing access to both
the hosts and the password manager would make the SOPS secrets unrecoverable.

