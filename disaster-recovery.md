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
| Borg passphrase | `secrets/hosts/<hostname>.yaml`; unique per host and shared by that host's Borg 1.4 and Borg 2 repositories |
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
- [x] `secrets/hosts/jay-desktop.yaml`

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

## Respond to an exposed private key

Loss and exposure are different incidents. A lost key can be replaced using the
recovery procedure above. If a private key might have been copied, assume that
every SOPS file revision encrypted to that key has been decrypted.

Removing a recipient from the current SOPS metadata does not revoke access to
older Git revisions. Rewriting Git history can reduce accidental exposure, but
cannot recall existing clones or cached objects. The underlying credentials
must therefore be rotated.

### 1. Determine the scope

The affected files depend on which key was exposed:

| Exposed key | SOPS and external scope |
| --- | --- |
| Recovery age identity | Every file revision containing the recovery recipient |
| Host SSH private key | Shared secrets, that host's secrets, and every SSH service trusting the key |
| Borg repository key and passphrase | All archives in that repository |
| OVH S3 credentials | Objects accessible to those credentials |

The recovery recipient currently appears in the files listed in the
recovery-recipient rollout section. After rollout is complete, exposure of the
recovery identity affects every SOPS file.

Use Git history to identify when a recipient was present:

```sh
git log --all --name-only --oneline \
  -S '<compromised-public-recipient>' -- secrets
```

### 2. Contain access

Act before modifying encrypted files:

1. Revoke exposed SSH keys, API tokens, cloud credentials, and password-manager
   sessions wherever possible.
2. Generate a replacement SOPS recovery identity if the recovery identity was
   exposed, and store it in the password manager.
3. Replace the compromised public recipient in `secrets/.sops.yaml`.

For each affected SOPS file, first update its recipients and then generate a
new data-encryption key:

```sh
cd /etc/nixos/secrets
sops updatekeys -y path/to/affected-file.yaml
sops rotate --in-place path/to/affected-file.yaml
```

The order matters: remove the compromised recipient before rotating the data
key. This is the procedure recommended by the
[SOPS key-management documentation](https://getsops.io/docs/usage/key-management/#rotating-secrets-after-a-key-in-a-key-group-has-been-compromised).

### 3. Rotate the actual secrets

SOPS rotation protects new file revisions, but the old revisions remain
decryptable with the compromised private key. Rotate every still-valid secret
that appeared in them:

- Revoke and replace GitHub tokens.
- Revoke and replace OVH S3 access keys.
- Revoke and replace Home Assistant tokens.
- Revoke Google OAuth access used by rclone, then reconnect it.
- Revoke or remove exposed Git signing keys and generate replacements.
- Remove exposed SSH public keys from every `authorized_keys` and service,
  generate new host keys, and update the SOPS recipients.
- Change ordinary passwords.

Commit the safely rewrapped files only after the compromised recipient has been
removed. Do not place replacement credentials into a file that the compromised
recipient can still decrypt.

### 4. Replace compromised Borg repositories

Changing a Borg passphrase does not replace the underlying repository
encryption key. If both a repository key and its passphrase may have been
exposed, create a new repository with fresh encryption key material, make and
verify a fresh backup, and retire the old repository. Previously copied data
from the old repository cannot be made confidential again.

Follow the compromise-specific warning in
[`migration/borg-passphrases.md`](migration/borg-passphrases.md#compromise-changes-the-procedure)
when planning the per-host passphrase migration and repository replacement.
Borg explicitly documents that changing the passphrase after the key and
passphrase were compromised does not protect past or future backups in that
repository:

- [Borg 1.4 key documentation](https://borgbackup.readthedocs.io/en/stable/usage/key.html#borg-key-change-passphrase)
- [Borg 2 key documentation](https://borgbackup.readthedocs.io/en/latest/usage/key.html#borg-key-change-passphrase)

### 5. Verify the new trust chain

After all rotations:

1. Test every remaining SOPS recipient.
2. Confirm the compromised recipient is absent from current encrypted files.
3. Confirm revoked credentials no longer authenticate.
4. Run the first backup to each new Borg repository and perform a restore test.
5. Review password-manager sessions and multi-factor recovery methods.
6. Record what was exposed, revoked, replaced, and verified.

## Password-manager resilience

An online-only recovery design makes the password-manager account the root of
trust and an availability dependency. Keep its account-recovery details and
multi-factor recovery method independent of these hosts. Losing access to both
the hosts and the password manager would make the SOPS secrets unrecoverable.
