# New host guide

This sets up another of Jay's machines using the current module layout. For a replacement machine, also follow [disaster recovery](../disaster-recovery.md), especially when replacing keys or reconnecting existing backups.

Start with a working NixOS installation, network access and this repository at `/etc/nixos`. Keep the installer-generated hardware configuration and the installation's `system.stateVersion`. This guide does not partition or format disks.

## 1. Register the host

Choose a hostname and use it consistently for the directory, module exports, NixOS configuration and host secrets file. The examples use `jay-new`.

Create `modules/hosts/jay-new/flake-parts.nix`:

```nix
{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "jay-new";
}
```

Create `modules/hosts/jay-new/configuration.nix`:

```nix
{ inputs, ... }:
{
  flake.modules.nixos.jay-new = {
    networking.hostName = "jay-new";

    imports = with inputs.self.modules.nixos; [
      role-laptop
      role-nix-builder
      user-jay
    ];

    my.displays.internal = {
      width = 1920;
      height = 1080;
      freq = "60";
    };

    # Bootstrap without Secure Boot signing keys. Remove these overrides after
    # setting up Lanzaboote and its PKI.
    boot.lanzaboote.enable = false;
    boot.loader.systemd-boot.enable = true;
  };

  flake.modules.homeManager.jay-new = {
    imports = with inputs.self.modules.homeManager; [
      role-laptop
    ];
  };
}
```

Use the panel's actual resolution and refresh rate. Change `role-laptop` to `role-desktop` in both namespaces for a desktop, and remove the internal display settings. For an appliance, start with `role-default` instead. `role-nix-builder` adds build tools, Nix GitHub authentication and the Attic cache; omit it where those are unnecessary. Add `role-gaming` in both namespaces if wanted.

`user-jay` connects the matching Home Manager host module automatically. You do not need `mkHomeManager` or a standalone `home.nix`.

## 2. Add hardware and storage

Use this machine's installer-generated hardware settings. If necessary, generate a fresh reference on the installed machine:

```sh
sudo nixos-generate-config --show-hardware-config > /tmp/new-host-hardware.nix
```

Wrap the generated NixOS module before putting it under `modules/`. For example, `hardware.nix` has this shape:

```nix
{ inputs, ... }:
{
  flake.modules.nixos.jay-new =
    { config, lib, modulesPath, ... }:
    {
      # Generated imports, kernel modules and hardware settings go here.
      # Add suitable reusable hardware modules from this repository as needed.
    };
}
```

Put filesystem, swap and LUKS definitions in `storage.nix`, wrapped in `flake.modules.nixos.jay-new` too. Definitions with the same module name merge automatically. Keep the generated `modulesPath` imports; do not copy another host's disk UUIDs or encrypted devices. A raw NixOS module directly under `modules/` would be evaluated as a flake-parts module.

The shared roles currently set both state versions to `25.11`. Preserve an existing installation's versions. If they differ from the shared values, override the relevant NixOS `system.stateVersion` and Home Manager `home.stateVersion` with `lib.mkForce` in the host modules. State versions are compatibility settings, independent of the chosen nixpkgs branch.

The shared bootloader defaults to Lanzaboote with keys at `/var/lib/sbctl`. The sample uses systemd-boot for the first activation. Set up signing keys and firmware enrollment using the [Lanzaboote instructions](https://github.com/nix-community/lanzaboote), then remove the bootstrap overrides and rebuild. Keep a working boot entry and LUKS passphrase throughout setup.

## 3. Authorize the host to decrypt secrets

System SOPS uses `/etc/ssh/ssh_host_ed25519_key`. This is separate from Jay's personal SSH key. On the new machine, generate any missing host keys and obtain its public age recipient:

```sh
sudo ssh-keygen -A
nix shell nixpkgs#ssh-to-age --command \
  ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub
```

On a machine that can already decrypt the secrets, load its temporary SOPS identity using [secrets/README.md](../secrets/README.md). Then:

1. Add the new public recipient to `keys` in `secrets/.sops.yaml`.
2. Add its anchor to the `shared.yaml` creation rule.
3. Add a rule for `hosts/jay-new.yaml` with the new host and recovery recipients.
4. From `secrets/`, run `sops updatekeys -y shared.yaml`.
5. Create `sops hosts/jay-new.yaml`. For a workstation with backups enabled, add a fresh, strong `storagebox-borg-passphrase`, unique to this host.
6. Rewrap any other encrypted files required by the selected modules for the new recipient.

Keep the recovery recipient in every applicable rule. Recipient rules affect new encryption; existing files need `sops updatekeys` to receive the change. Transfer the updated encrypted files and configuration to the new machine. The private host key stays on that machine.

If enabling WireGuard or another service with host-specific credentials, provision those credentials and unique addresses before activation too. Do not copy a peer's private key or address.

## 4. Build and activate

Make the new files Git-tracked so the flake can see them. Adding a host module does not require regenerating `flake.nix`; only changes to its generated contents do.

From `/etc/nixos` on the new machine:

```sh
nix fmt
nix eval .#nixosConfigurations.jay-new.config.system.build.toplevel.drvPath
nix build .#nixosConfigurations.jay-new.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#jay-new
```

Log in as Jay. Confirm Home Manager activated and the root SOPS service succeeded:

```sh
systemctl status sops-nix.service
systemctl status home-manager-jay.service
```

For a workstation with backups enabled, check that Jay can read the generated credentials without printing them:

```sh
test -r /run/secrets/storagebox-borg-passphrase
test -r /run/secrets/ovh-borg2-aws-credentials
```

Home Manager generates missing personal SSH keys. Git's signing setup imports the existing encrypted signing key. Authorize the new personal SSH public key on the services this machine needs, including both Storage Boxes if using backups.

## 5. Initialize backups

Workstations enable Borgmatic by default. A new host uses two Borg 1.4 repositories on Hetzner and one Borg 2 repository on OVH. Complete this section as Jay after activation. A replacement host may already have repositories; inspect and reconnect those using the recovery guide instead of creating new ones.

First authorize `~/.ssh/id_ed25519.pub` on both Storage Boxes and verify SSH access on port 23. Then initialize the new repositories:

```sh
(
  set -eu
  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND='cat /run/secrets/storagebox-borg-passphrase'
  export BORG_RSH="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"
  host_name="$(hostname)"

  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}"
  borg init --remote-path borg-1.4 --encryption=repokey-blake2 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}"

  export AWS_SHARED_CREDENTIALS_FILE=/run/secrets/ovh-borg2-aws-credentials
  export AWS_DEFAULT_REGION=gra AWS_REGION=gra
  export BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}"
  borg2 repo-create --encryption aes256-ocb --id-hash blake3 --key-location repokey
)
```

Export all three repository keys into the encrypted host file. The passphrase alone cannot recover a lost repokey. Load a temporary SOPS identity as described in [the secrets guide](../secrets/README.md), then run from `/etc/nixos/secrets`:

```sh
(
  set -eu
  umask 077
  key_dir="$(mktemp -d "${XDG_RUNTIME_DIR:?}/borg-keys.XXXXXX")"
  trap 'rm -rf "$key_dir"' EXIT
  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND='cat /run/secrets/storagebox-borg-passphrase'
  export BORG_RSH="ssh -i $HOME/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"
  host_name="$(hostname)"

  borg key export --remote-path borg-1.4 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}" "$key_dir/fsn1"
  borg key export --remote-path borg-1.4 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}" "$key_dir/hel1"

  export AWS_SHARED_CREDENTIALS_FILE=/run/secrets/ovh-borg2-aws-credentials
  export AWS_DEFAULT_REGION=gra AWS_REGION=gra
  export BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}"
  borg2 key export "$key_dir/ovh"

  jq -Rs . < "$key_dir/fsn1" | sops set --value-stdin \
    "hosts/${host_name}.yaml" '["hetzner-fsn1-borg1.4-repokey"]'
  jq -Rs . < "$key_dir/hel1" | sops set --value-stdin \
    "hosts/${host_name}.yaml" '["hetzner-hel1-borg1.4-repokey"]'
  jq -Rs . < "$key_dir/ovh" | sops set --value-stdin \
    "hosts/${host_name}.yaml" '["ovh-borg2-repokey"]'
)
```

Remove the temporary SOPS identity when finished. Keep the updated encrypted host file in the repository and preserve the independent recovery identity as described in [disaster recovery](../disaster-recovery.md).

Run the first backups and check the timer:

```sh
borgmatic --config ~/.config/borgmatic.d/borg1.4.yaml create
borgmatic --config ~/.config/borgmatic.d/borg2.yaml create
borgmatic --config ~/.config/borgmatic.d/borg1.4.yaml repo-info
borgmatic --config ~/.config/borgmatic.d/borg2.yaml repo-info
systemctl --user list-timers borgmatic.timer
```

Add host-specific exclusions and healthcheck URLs under `programs.borgmatic.backups.<name>.settings` in the Home Manager host module. Extend exclusion lists with `lib.mkAfter`; preserve the shared defaults.

## 6. Finish host-specific setup

- Register the new Syncthing device ID on its peers. Update the device definitions and personal/work host lists in `role-workstation` so the intended folders are declared and shared.
- Review desk imports and monitor identifiers. Laptop display dimensions belong in the host; physical desk layouts belong in `modules/desks/`.
- Review gaming options if enabled. Only the Game Boy cores are selected by default; emulator state syncing and backup exclusions remain configured independently of emulator activation.
- Verify a reboot, encrypted-disk unlock, networking and the first backups before considering setup complete.
