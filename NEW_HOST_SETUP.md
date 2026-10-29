# New Host Setup Guide

This repo can bootstrap a new personal machine, but a few steps are still
interactive on purpose. In particular, it no longer tries to run `ssh-copy-id`
during activation.

## 1. Add The Host Config

Create a new host directory under `hosts/` and add its `configuration.nix` and
`home.nix`. Borgmatic is configured through Home Manager, so put any
per-device overrides in `home.nix`. The shared module configures a Borg 1
backup to both Hetzner repositories and a Borg 2 backup to OVH Object Storage,
all using the hostname; only add settings that differ from those defaults.
Apply source and exclusion overrides to both named configurations when they
should remain identical:

```nix
programs.borgmatic.backups = {
  "borg1.4".location = {
    sourceDirectories = lib.mkAfter [ "/srv/projects" ];
    repositories = lib.mkAfter [
      {
        label = "usb";
        path = "/run/media/jay/BACKUP/${config.networking.hostName}";
      }
    ];
    extraConfig.exclude_patterns = lib.mkAfter [
      "${config.home.homeDirectory}/.config/obs-studio"
    ];
  };

  borg2.location = {
    sourceDirectories = lib.mkAfter [ "/srv/projects" ];
    extraConfig.exclude_patterns = lib.mkAfter [
      "${config.home.homeDirectory}/.config/obs-studio"
    ];
  };

  "borg1.4".hooks.extraConfig.healthchecks = {
    ping_url = "https://hc-ping.com/replace-me";
    send_logs = true;
  };

  borg2.hooks.extraConfig.healthchecks = {
    ping_url = "https://hc-ping.com/replace-me";
    send_logs = true;
  };
};

services.borgmatic.frequency = "daily";
```

Use `lib.mkAfter` when appending source directories, repositories, or exclude
patterns, so the shared defaults remain intact. Application modules append
their own excludes directly—for example Discord, Spotify, and Steam—so the
shared base list stays focused on generic clutter.

## 2. Add The Host SSH Key To SOPS And Create Host Secrets

Create the root-owned host key before the first configuration that decrypts
system SOPS files:

```sh
sudo install -d -m 700 /etc/ssh
if ! sudo test -e /etc/ssh/ssh_host_ed25519_key; then
  sudo ssh-keygen -q -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
fi
```

Convert its public key to an age recipient:

```sh
cd /etc/nixos
nix shell nixpkgs#ssh-to-age --command sh -c \
  'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
```

Add the new recipient to `secrets/.sops.yaml`:

- add a new key anchor under `keys:`
- add it alongside recovery to the `shared.yaml`, `obojima-glyph.ttf.json`,
  and `hosts/<hostname>.yaml` rules

The shared NixOS role already configures
`/etc/ssh/ssh_host_ed25519_key` as the SOPS identity, so do not add a host
override. The full consumer migration and validation process is documented in
[secrets/SYSTEM_SOPS_BOOT_MIGRATION.md](secrets/SYSTEM_SOPS_BOOT_MIGRATION.md).

Then create or update that host's secret file from a machine that can already
decrypt and edit secrets:

```sh
cd /etc/nixos/secrets
nix shell nixpkgs#sops --command sops hosts/<hostname>.yaml
```

Set `storagebox-borg-passphrase` in that file.

- Generate a unique value for this host; never reuse it on another host.
- The host's Borg 1.4 and Borg 2 repositories deliberately share this one
  passphrase.

If you changed recipients in `secrets/.sops.yaml`, refresh recipient metadata:

```sh
cd /etc/nixos/secrets
nix shell nixpkgs#sops --command sops updatekeys -y hosts/<hostname>.yaml
```

Do not commit `~/.ssh/id_ed25519.pub`. Keep it local and distribute it directly
to any external SSH service that needs it; it is not a SOPS recipient.

Recommended flow for a new device:

1. Create the root-owned host key and derive its recipient.
2. Add the host recipient and recovery recipient to `.sops.yaml` rules.
3. Create/edit `secrets/hosts/<hostname>.yaml` from an already authorised host.
4. Rewrap every affected file with `sops updatekeys -y`.
5. Commit the encrypted metadata.
6. Build, switch, and verify the system secret manifest before rebooting.

## 3. Apply The NixOS Config

Build and switch to the new host configuration:

```sh
cd /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
```

This generates the local SSH and GPG keys automatically when they are missing.

## Secure Boot And Passphrase Drive Unlock Setup

Laptop boot uses a graphical Plymouth LUKS prompt instead of TPM-backed
unlock. After entering the disk passphrase, the configured user is logged into
the default Hyprland session automatically. Dux remains available as the
graphical greeter after logout.

Before you start:

- This repo uses `lanzaboote`, stores Secure Boot keys under `/var/lib/sbctl`,
  and enables `systemd` plus Plymouth in the initrd.
- Keep a tested LUKS passphrase for every encrypted volume before removing a
  TPM enrollment.

1. Check the current boot and disk state:

```sh
sudo bootctl status
lsblk -o NAME,PATH,FSTYPE,UUID,MOUNTPOINTS
findmnt -no SOURCE /
swapon --show
```

2. If Secure Boot is not set up yet, create and enroll the keys:

```sh
sudo sbctl create-keys
sudo sbctl verify
sudo sbctl enroll-keys --microsoft
sudo reboot now
```

3. Identify every LUKS volume that may have a TPM enrollment. Remove only the
   TPM token; this does not remove the normal passphrase keyslot.

For `jay-framework`, the current layout is:

- `/dev/nvme0n1p2` for the encrypted root volume
- `/dev/nvme0n1p3` for a separate encrypted swap volume

Label its GPT partitions once so the storage configuration can use the same
stable paths as the other machines. Confirm the partition layout with `lsblk`
before running these commands:

`parted` is not installed permanently. Run it from a temporary Nix shell; the
resolved store path is passed to `sudo`, so no root profile change is needed:

```sh
nix shell nixpkgs#parted -c sh -c '
  sudo "$(command -v parted)" /dev/nvme0n1 name 1 nixos-efi
  sudo "$(command -v parted)" /dev/nvme0n1 name 2 nixos-crypt
  sudo "$(command -v parted)" /dev/nvme0n1 name 3 nixos-swap
'
```

Verify the labels before rebuilding:

```sh
ls -l /dev/disk/by-partlabel/nixos-{efi,crypt,swap}
```

For `jay-mopo`, remove the TPM enrollment from its encrypted root volume:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/disk/by-partlabel/nixos-crypt
```

For `jay-framework`, remove TPM enrollment from both encrypted volumes if they
were enrolled:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 \
  /dev/disk/by-partlabel/nixos-crypt
sudo systemd-cryptenroll --wipe-slot=tpm2 \
  /dev/disk/by-partlabel/nixos-swap
```

4. Rebuild the laptop configuration, then reboot and confirm that Plymouth
prompts for the LUKS passphrase and starts the desktop without a second login:

```sh
cd /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>
sudo reboot
```

Notes:

- `--wipe-slot=tpm2` removes only TPM-backed enrollments on that volume; it
  does not remove a passphrase keyslot.
- Check the configured LUKS tokens before and after the change with
  `sudo systemd-cryptenroll --dump /dev/<luks-volume>`.

## 4. Copy The SSH Key To Remote Machines

Run these manually so password prompts and host-key prompts work normally:

```sh
ssh-copy-id -s -i ~/.ssh/id_ed25519.pub -p 23 \
  u551190@u551190.your-storagebox.de
ssh-copy-id -s -i ~/.ssh/id_ed25519.pub -p 23 \
  u650719@u650719.your-storagebox.de
```

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub -o IdentitiesOnly=yes -p 22 \
  jay@home.turnr.net
```

## 5. Initialize The Borg Repositories

The Hetzner configuration is pinned to Borg 1.4.x locally and uses `borg-1.4`
on the Storage Box side. The OVH configuration uses the latest packaged Borg 2
beta and connects directly to its S3-compatible API.

Create both Storage Box repositories manually once per host. The system
`sops-nix` activation must already have decrypted the Borg passphrase and OVH
credentials into `/run/secrets`:

```sh
test -r /run/secrets/storagebox-borg-passphrase
test -r /run/secrets/ovh-borg2-aws-credentials
```

Initialize the two Borg 1.4 Storage Box repositories:

```sh
(
  set -euo pipefail

  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND='cat /run/secrets/storagebox-borg-passphrase'
  export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"

  host_name="$(hostname)"

  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}"

  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}"
)
```

Create the host's Borg 2 repository in the `borg-2` OVH bucket:

```sh
(
  set -euo pipefail

  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND='cat /run/secrets/storagebox-borg-passphrase'
  export AWS_SHARED_CREDENTIALS_FILE=/run/secrets/ovh-borg2-aws-credentials
  export AWS_DEFAULT_REGION=gra
  export AWS_REGION=gra
  export BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/$(hostname)"

  borg2 repo-create \
    --encryption aes256-ocb \
    --id-hash blake3 \
    --key-location repokey

  borg2 repo-info

  # Optional: reserve about 1 GiB of billable object storage so Borg can still
  # recover from a storage-full condition.
  # borg2 repo-space --reserve 1G
)
```

Export all three repository keys into the host's SOPS file. Although the
repositories share a passphrase, every repository has its own key. The SOPS
file uses the `age1...` identity derived from the root-owned OpenSSH host key,
so convert that key with `ssh-to-age`; passing the raw SSH key directly to SOPS
will not match the recipient.

```sh
(
  set -euo pipefail

  sudo -v

  host_name="$(hostname)"
  fsn1_key="$(mktemp)"
  hel1_key="$(mktemp)"
  ovh_key="$(mktemp)"
  sops_identity="$(mktemp)"
  trap 'rm -f "$fsn1_key" "$hel1_key" "$ovh_key" "$sops_identity"' EXIT

  ssh_to_age_store="$(
    nix build --no-link --print-out-paths nixpkgs#ssh-to-age
  )"
  sudo -n "${ssh_to_age_store}/bin/ssh-to-age" \
    -private-key \
    -i /etc/ssh/ssh_host_ed25519_key >"$sops_identity"

  unset SOPS_AGE_SSH_PRIVATE_KEY_CMD SOPS_AGE_SSH_PRIVATE_KEY_FILE
  export SOPS_AGE_KEY_FILE="$sops_identity"

  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND='cat /run/secrets/storagebox-borg-passphrase'
  export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$fsn1_key"

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$hel1_key"

  export AWS_SHARED_CREDENTIALS_FILE=/run/secrets/ovh-borg2-aws-credentials
  export AWS_DEFAULT_REGION=gra
  export AWS_REGION=gra
  export BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}"

  borg2 key export /dev/stdout >"$ovh_key"

  cd /etc/nixos/secrets

  jq -Rs . <"$fsn1_key" \
    | sops set --value-stdin \
        "hosts/${host_name}.yaml" \
        '["hetzner-fsn1-borg1.4-repokey"]'

  jq -Rs . <"$hel1_key" \
    | sops set --value-stdin \
        "hosts/${host_name}.yaml" \
        '["hetzner-hel1-borg1.4-repokey"]'

  jq -Rs . <"$ovh_key" \
    | sops set --value-stdin \
        "hosts/${host_name}.yaml" \
        '["ovh-borg2-repokey"]'

  sops decrypt "hosts/${host_name}.yaml" >/dev/null

  rg -o \
    '^(hetzner-(fsn1|hel1)-borg1\.4-repokey|ovh-borg2-repokey):' \
    "hosts/${host_name}.yaml"
)
```

Host secret files should be encrypted to both that host's SSH-derived age
recipient and the dedicated recovery recipient. This keeps the exported keys
decryptable after losing the host without requiring reuse of its operational
SSH private key. See [`disaster-recovery.md`](disaster-recovery.md) for the
recovery-key design and complete restore procedure.

The exported keys remain encrypted and still require the host's Borg
passphrase. Each host must initialize its own hostname prefix. If either file
under `/run/secrets` is missing, fix the system `sops-nix` activation before
continuing; do not fall back to the retired Home Manager secret paths.

If you want to confirm the versions first:

```sh
borg --version
borg2 --version
ssh -p 23 u551190@u551190.your-storagebox.de borg-1.4 --version
```

## 6. Run The First Backup

Once the key is installed and the repo exists:

```sh
borgmatic --config ~/.config/borgmatic.d/borg1.4.yaml create
borgmatic --config ~/.config/borgmatic.d/borg2.yaml create
```

The scheduled `borgmatic.service` discovers both files in `borgmatic.d` and
runs them sequentially from the same daily timer.

Useful follow-up checks:

```sh
borgmatic --config ~/.config/borgmatic.d/borg1.4.yaml repo-info
borgmatic --config ~/.config/borgmatic.d/borg2.yaml repo-info
systemctl --user list-timers | rg borgmatic
```
