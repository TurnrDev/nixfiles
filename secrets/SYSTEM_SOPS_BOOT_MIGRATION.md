# SOPS host-key migration

Run this once on each host, then delete this file after every host is checked
off. The shared NixOS configuration already uses the root-owned host key; no
per-host Nix edits are needed.

## Progress

- [ ] `jay-desktop`
- [ ] `jay-framework`
- [x] `jay-mopo`

## Runbook

Do one host at a time. Do not remove its personal SOPS recipient until step 3
succeeds.

### 1. Add this host's key

```sh
cd /etc/nixos
git pull --ff-only

if ! sudo test -e /etc/ssh/ssh_host_ed25519_key; then
  sudo ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
fi

nix shell nixpkgs#ssh-to-age --command sh -c \
  'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

Copy the printed `age1...` recipient. In `secrets/.sops.yaml`, add it under
`keys:` and to the rules for `shared.yaml`, `obojima-glyph.ttf.json`, and
`hosts/<hostname>.yaml`. Keep the old personal recipient and recovery
recipient for now.

### 2. Rewrap and prove the host key works

```sh
cd /etc/nixos/secrets
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
sops updatekeys -y shared.yaml
sops updatekeys -y obojima-glyph.ttf.json
sops updatekeys -y "hosts/$(hostname).yaml"

cd /etc/nixos
nix flake check
nix build ".#nixosConfigurations.$(hostname).config.system.build.toplevel" --no-link
sudo nixos-rebuild switch --flake ".#$(hostname)"
sudo ls -lL /run/secrets
```

The switch must succeed and expected files must appear in `/run/secrets`. It
uses the host key as root, so this proves the boot-time decryption path works.
If it fails, stop: the personal recipient is still available.

### 3. Remove the personal SOPS recipient

Only after step 2 succeeds, edit `secrets/.sops.yaml` again. Replace this
host's old personal `age1...` recipient with the new host recipient. Keep the
recovery recipient.

```sh
cd /etc/nixos/secrets
sops updatekeys -y shared.yaml
sops updatekeys -y obojima-glyph.ttf.json
sops updatekeys -y "hosts/$(hostname).yaml"

cd /etc/nixos
sudo nixos-rebuild switch --flake ".#$(hostname)"
```

The second switch must succeed.

### 4. Reboot and check off the host

Reboot normally. After login:

```sh
sudo ls -lL /run/secrets
systemctl --user status borgmatic.service import-git-signing-key.service rclone-gdrive.service
```

If a secret is missing:

```sh
journalctl -b -u nixos-activation.service
```

Tick this host in **Progress** only after these checks pass.

## Final cleanup

After every host is checked off:

1. Delete `secrets/SYSTEM_SOPS_BOOT_MIGRATION.md`.
2. Commit that deletion with the completed migration branch.

Keep the recovery recipient. Do not commit personal SSH public keys or any
private key.
