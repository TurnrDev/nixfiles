# New Host Setup Guide

This repo can bootstrap a new personal machine, but a few steps are still
interactive on purpose. In particular, it no longer tries to run `ssh-copy-id`
during activation.

## 1. Add The Host Config

Create a new host directory under `hosts/` and add its `configuration.nix`.
Per-device Borgmatic overrides belong in the host config, for example:

```nix
my.backups.borgmatic = {
  frequency = "hourly";
  sourceDirectories = [ config.my.identity.homeDirectory ];
  excludePatterns = [
    "${config.my.identity.homeDirectory}/.cache"
    "${config.my.identity.homeDirectory}/Downloads"
    "${config.my.identity.homeDirectory}/.local/share/Trash"
  ];
  healthchecksUrl = "https://hc-ping.com/replace-me";
  repositories = {
    storagebox.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
  };
};
```

Add more repositories later by extending `my.backups.borgmatic.repositories`.
The shared Borgmatic module already supports multiple repositories per device.

## 2. Add The Host SSH Key As An Age Recipient

After the new machine has generated `~/.ssh/id_ed25519`, commit its public key
into the repo as `hosts/<hostname>/id_ed25519.pub`.

Then reference that file from `secrets/secrets.nix` and add it to the
recipient list for `storagebox-borg-passphrase.age`.

Important: do not replace the existing recipient list when adding a new device.
Add the new public key alongside the old ones. If you remove `jay-framework`
from the list and rekey the secret, `jay-framework` will lose access.

Then, from a machine that can already decrypt the secret, rekey it:

```sh
cd /etc/nixos
EDITOR=nano RULES=/etc/nixos/secrets/secrets.nix \
  nix run github:ryantm/agenix -- -r
```

That command is safe as long as `secrets/secrets.nix` contains both the old and
new recipients. It re-encrypts the same plaintext to the full recipient set.

Only use `-e` when either:

- the secret does not exist yet, or
- you intentionally want to change the shared Borg passphrase plaintext

If the passphrase secret does not exist yet, create it from a machine that has
the private key you want to use for editing:

```sh
cd /etc/nixos
EDITOR=nano RULES=/etc/nixos/secrets/secrets.nix \
  nix run github:ryantm/agenix -- -e /etc/nixos/secrets/storagebox-borg-passphrase.age \
  -i /home/jay/.ssh/id_ed25519
```

You said you want to choose the passphrase yourself, so type the exact shared
passphrase you want into the editor when agenix opens.

Recommended flow for a new device:

1. Rebuild the new host once so it creates `~/.ssh/id_ed25519`.
2. Commit that public key as `hosts/<hostname>/id_ed25519.pub`.
3. Reference it from `secrets/secrets.nix` alongside the existing keys.
4. On an already-authorized machine, run `agenix -r`.
5. Commit both `secrets/secrets.nix` and `secrets/storagebox-borg-passphrase.age`.
6. Rebuild the new machine again so it can decrypt the shared secret.

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
```

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub -o IdentitiesOnly=yes -p 22 \
  jay@home.turnr.dev
```

## 5. Initialize The Borg Repository

The repo is pinned to Borg 1.4.x locally and configured to use `borg-1.4` on
the Storage Box side.

Create the Storage Box repo manually once per host. Use the exact same shared
passphrase you stored in `storagebox-borg-passphrase.age`:

```sh
export BORG_PASSPHRASE='your-shared-passphrase'
bash -c '
  borg repo-create --remote-path borg-1.4 --encryption=repokey-blake2 \
  ssh://u551190@u551190.your-storagebox.de:23/./$(hostname)
'
unset BORG_PASSPHRASE
```

If you want to confirm the versions first:

```sh
borg --version
ssh -p 23 u551190@u551190.your-storagebox.de borg-1.4 --version
```

## 6. Run The First Backup

Once the key is installed and the repo exists:

```sh
borgmatic --config ~/.config/borgmatic.d/shared.yaml create
```

Useful follow-up checks:

```sh
borgmatic --config ~/.config/borgmatic.d/shared.yaml repo-info
systemctl --user list-timers | rg borgmatic
```
