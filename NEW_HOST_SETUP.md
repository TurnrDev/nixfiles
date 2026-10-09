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

## Optional: Secure Boot And TPM Drive Unlock Setup

Use this section when setting up Secure Boot and TPM-backed LUKS unlock on a
new machine.

Before you start:

- This repo uses `lanzaboote`, stores Secure Boot keys under `/var/lib/sbctl`,
  and enables `systemd` in the initrd.
- Keep a normal passphrase or recovery path available for each LUKS volume
  before changing TPM enrollment.
- Decide whether you want TPM unlock for root only, or for root plus any
  separate encrypted swap volume.

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

3. Identify the LUKS volume for root, and decide whether you also want TPM
   enrollment on any separate encrypted swap volume.

For `jay-framework`, the current layout is:

- `/dev/nvme0n1p2` for the encrypted root volume
- `/dev/nvme0n1p3` for a separate encrypted swap volume

4. Choose the PCR policy deliberately before enrolling TPM.

- Do not blindly reuse `0+2+7+12`.
- `man systemd-cryptenroll` warns that PCRs `0` and `2` are more brittle
  across firmware and hardware changes.
- A less brittle starting point is usually some combination of `7` and `11`,
  with `14` added when shim/MOK is part of the boot chain.

5. Enroll the root LUKS volume into TPM:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs='<chosen-pcrs>' \
  --wipe-slot=tpm2 /dev/<root-luks-partition>
```

6. If you also want TPM enrollment for a separate encrypted swap volume,
   enroll that volume too:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs='<chosen-pcrs>' \
  --wipe-slot=tpm2 /dev/<swap-luks-partition>
```

7. Reboot and confirm the machine still unlocks as expected.

Notes:

- `--wipe-slot=tpm2` only replaces TPM-backed enrollments on that LUKS volume.
- If unlock behavior becomes fragile after firmware or boot-chain changes,
  revisit the PCR set rather than reusing an old command verbatim.

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

Create both Storage Box repositories manually once per host. This setup
decrypts the host passphrase into the Home Manager `sops-nix` runtime symlink
directory:

```sh
export BORG_PASSPHRASE="$(cat "${HOME}/.config/sops-nix/secrets/storagebox-borg-passphrase")"
bash -c '
  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
  ssh://u551190@u551190.your-storagebox.de:23/./$(hostname) && \
  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
  ssh://u650719@u650719.your-storagebox.de:23/./$(hostname)
'
unset BORG_PASSPHRASE
```

Export both Borg 1.4 repository keys. Although the repositories share a
passphrase, each repository has its own key. The exported keys remain encrypted
and still require the original passphrase for recovery:

```sh
(
  set -euo pipefail

  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND="cat ${HOME}/.config/sops-nix/secrets/storagebox-borg-passphrase"
  export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"

  host_name="$(hostname)"
  key_file="$(mktemp)"
  trap 'rm -f "$key_file"' EXIT

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$key_file"

  jq -Rs . <"$key_file" \
    | (cd /etc/nixos/secrets && \
        sops set --value-stdin \
          "hosts/${host_name}.yaml" \
          '["hetzner-fsn1-borg1.4-repokey"]')

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$key_file"

  jq -Rs . <"$key_file" \
    | (cd /etc/nixos/secrets && \
        sops set --value-stdin \
          "hosts/${host_name}.yaml" \
          '["hetzner-hel1-borg1.4-repokey"]')
)
```

Host secret files should be encrypted to both that host's SSH-derived age
recipient and the dedicated recovery recipient. This keeps the exported keys
decryptable after losing the host without requiring reuse of its operational
SSH private key. See [`disaster-recovery.md`](disaster-recovery.md) for the
recovery-key design and complete restore procedure.

Create the host's Borg 2 repository in the `borg-2` OVH bucket after rebuilding
so that the rendered S3 credentials and `borg2` executable are available:

```sh
export BORG_PASSPHRASE="$(cat "${HOME}/.config/sops-nix/secrets/storagebox-borg-passphrase")"
export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.config/sops-nix/secrets/rendered/ovh-borg2-aws-credentials"
export AWS_DEFAULT_REGION=gra
export AWS_REGION=gra
export BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/$(hostname)"

borg2 repo-create \
  --encryption aes256-ocb \
  --id-hash blake3 \
  --key-location repokey

# Keep an encrypted recovery copy of the repokey outside the repository.
borg2 key export /dev/stdout \
  | jq -Rs . \
  | (cd /etc/nixos/secrets && \
      sops set --value-stdin "hosts/$(hostname).yaml" '["ovh-borg2-repokey"]')

unset BORG_REPO AWS_REGION AWS_DEFAULT_REGION AWS_SHARED_CREDENTIALS_FILE BORG_PASSPHRASE
```

The exported key remains encrypted and still requires the host's existing Borg
passphrase. Each host must initialize its own hostname prefix because host
secret files are encrypted to that host's age recipient.

If the passphrase or rendered credentials file is missing, start the user
secret service first:

```sh
systemctl --user start sops-nix.service
```

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
