# New Host Setup Guide

This repo can bootstrap a new personal machine, but a few steps are still
interactive on purpose. In particular, it no longer tries to run `ssh-copy-id`
during activation.

## 1. Add The Host Config

Create a new host directory under `hosts/` and add its `configuration.nix`.
Per-device Borgmatic overrides belong in the host config, for example:

```nix
my.backups.borgmatic = {
  frequency = "daily";
  sourceDirectories = [ config.my.identity.homeDirectory ];
  extraSourceDirectories = [ "/srv/projects" ];
  extraExcludePatterns = [ "${config.my.identity.homeDirectory}/.config/obs-studio" ];
  healthchecksUrl = "https://hc-ping.com/replace-me";
  repositories = {
    hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
  };
};
```

Add more repositories later by extending `my.backups.borgmatic.repositories`.
The shared Borgmatic module already supports multiple repositories per device.
Use `extraSourceDirectories` and `extraExcludePatterns` when a host needs to
append more paths without replacing the shared defaults.
App-specific excludes are also added automatically by the modules that enable
those programs, so the shared base list can stay focused on generic clutter.

## 2. Add The Host SSH Key To SOPS And Create Host Secrets

After the new machine has generated `~/.ssh/id_ed25519`, commit its public key
into the repo as `hosts/<hostname>/id_ed25519.pub`.

Convert that SSH public key to an age recipient:

```sh
cd /etc/nixos
nix shell nixpkgs#ssh-to-age --command sh -c \
  'ssh-to-age < hosts/<hostname>/id_ed25519.pub'
```

From an existing authorized machine, ensure `sops` can decrypt by exporting an
age key derived from your SSH private key:

```sh
mkdir -p ~/.config/sops/age
nix shell nixpkgs#ssh-to-age --command ssh-to-age \
  -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

Add the new recipient to `secrets/.sops.yaml`:

- add a new key anchor under `keys:`
- add/update a `creation_rules` entry for `hosts/<hostname>.yaml`

Important: do not replace existing recipients when adding a device. Add the new
recipient alongside existing ones, otherwise older machines may lose access.

Then create or update that host's secret file from a machine that can already
decrypt and edit secrets:

```sh
cd /etc/nixos/secrets
nix shell nixpkgs#sops --command sops hosts/<hostname>.yaml
```

Set `storagebox-borg-passphrase` in that file.

- Use the same value across hosts for a shared passphrase.
- Use a different value per host if you want host-specific credentials.

If you changed recipients in `secrets/.sops.yaml`, refresh recipient metadata:

```sh
cd /etc/nixos/secrets
nix shell nixpkgs#sops --command sops updatekeys -y hosts/<hostname>.yaml
```

Recommended flow for a new device:

1. Rebuild the new host once so it creates `~/.ssh/id_ed25519`.
2. Commit `hosts/<hostname>/id_ed25519.pub`.
3. Add the new age recipient and host rule in `secrets/.sops.yaml`.
4. Create/edit `secrets/hosts/<hostname>.yaml` with `sops`.
5. Commit `secrets/.sops.yaml` and `secrets/hosts/<hostname>.yaml`.
6. Rebuild the new machine again so it can decrypt its host secret file.

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

Create the Storage Box repo manually once per host. This setup decrypts the
host passphrase into the Home Manager `sops-nix` runtime symlink directory:

```sh
export BORG_PASSPHRASE="$(cat "${HOME}/.config/sops-nix/secrets/storagebox-borg-passphrase")"
bash -c '
  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
  ssh://u551190@u551190.your-storagebox.de:23/./$(hostname)
'
unset BORG_PASSPHRASE
```

If that file is missing, start the user secret service first:

```sh
systemctl --user start sops-nix.service
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
