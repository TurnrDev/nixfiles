SOPS secrets layout
===================

This repo uses two scopes for secrets:

- `shared.yaml`: same secret values for multiple machines.
- `hosts/<hostname>.yaml`: host-specific values.

For the separate migration that lets NixOS decrypt system secrets before
`/home` is mounted, see [SYSTEM_SOPS_BOOT_MIGRATION.md](SYSTEM_SOPS_BOOT_MIGRATION.md).

`.sops.yaml` lives in this directory, so run commands from `/etc/nixos/secrets`:

```sh
cd /etc/nixos/secrets
```

If `sops` is not installed globally, use:

```sh
nix shell nixpkgs#sops --command sops <args...>
```

Legacy key setup (temporary migration aid)
------------------------------------------

The following personal-key setup is only for files that still contain a legacy
personal recipient during migration. New hosts and fully migrated hosts use
the root-only OpenSSH host key instead; follow
[SYSTEM_SOPS_BOOT_MIGRATION.md](SYSTEM_SOPS_BOOT_MIGRATION.md) for editing and
recipient changes.

```sh
mkdir -p ~/.config/sops/age
nix shell nixpkgs#ssh-to-age --command ssh-to-age \
  -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Do not configure this identity in Home Manager. Once a host has been migrated,
the personal identity must no longer decrypt its SOPS files.

Example
-------

Use the same key name across hosts when values differ:

- `hosts/jay-framework.yaml`
  - `storagebox-borg-passphrase: hello`
- `hosts/jay-pc.yaml`
  - `storagebox-borg-passphrase: goodbye`

Add a secret
------------

Add a shared secret:

```sh
cd /etc/nixos/secrets
sops shared.yaml
```

Then add a key in the editor, for example:

```yaml
github-token: ghp_example
```

The OVH Borg 2 setup stores its bucket credentials as shared secrets so every
configured host can render a private boto3 credentials file:

```yaml
ovh-borg2-s3-access-key-id: example-access-key
ovh-borg2-s3-secret-access-key: example-secret-key
```

GitHub API rate limits for Nix flakes
-------------------------------------

Nix needs GitHub credentials before it can evaluate this flake, so the token
cannot be bootstrapped from a SOPS-managed NixOS secret on a brand new machine.
Bootstrap with a local root-only Nix config include first:

```sh
sudo install -d -m 0755 /etc/nix
printf 'access-tokens = github.com=ghp_example\n' \
  | sudo tee /etc/nix/github-access-token.conf >/dev/null
sudo chmod 0600 /etc/nix/github-access-token.conf
```

Replace `ghp_example` with a GitHub personal access token. The shared NixOS
role includes this file with `!include`, so machines without it keep working.
For the first rebuild, before the generated secret-backed file can exist, either
put the same `access-tokens = ...` line in `~/.config/nix/nix.conf`
temporarily or run the rebuild with:

```sh
sudo env NIX_CONFIG='access-tokens = github.com=ghp_example' nixos-rebuild switch --flake /etc/nixos
```

After that bootstrap rebuild succeeds, store the raw token in shared secrets so
future rebuilds render `/etc/nix/github-access-token.conf` automatically:

```sh
cd /etc/nixos/secrets
sops shared.yaml
```

Then add:

```yaml
github-token: ghp_example
```

The system role decrypts `github-token` and writes the include file as:

```conf
access-tokens = github.com=...
```

Add a host-specific secret:

```sh
cd /etc/nixos/secrets
sops hosts/jay-framework.yaml
```

Then add a key in the editor, for example:

```yaml
storagebox-borg-passphrase: my-framework-passphrase
```

After initializing the host's OVH Borg 2 repository, its encrypted recovery key
is also stored in the host file as `ovh-borg2-repokey`. The recovery key does
not replace the passphrase; both are needed for recovery.

Update a secret
---------------

Update a shared secret value:

```sh
cd /etc/nixos/secrets
sops shared.yaml
```

Update a host secret value:

```sh
cd /etc/nixos/secrets
sops hosts/jay-framework.yaml
```

In both cases, edit the value and save.

Remove a secret
---------------

Remove a key from shared secrets:

```sh
cd /etc/nixos/secrets
sops shared.yaml
```

Remove a key from host secrets:

```sh
cd /etc/nixos/secrets
sops hosts/jay-framework.yaml
```

In both cases, delete the key in the editor and save.

Add a new host key
------------------

1. Create or identify the root-owned `/etc/ssh/ssh_host_ed25519_key` on the
   target machine.
2. Convert `/etc/ssh/ssh_host_ed25519_key.pub` to an age recipient.
3. Add it plus recovery to the `.sops.yaml` shared, binary, and host-file
   rules.
4. The shared NixOS role already uses the host key; do not add a per-host Nix
   override.
5. Rewrap every affected file with `sops updatekeys -y`.

Follow [SYSTEM_SOPS_BOOT_MIGRATION.md](SYSTEM_SOPS_BOOT_MIGRATION.md) for the
complete ordered procedure and verification commands.

Refresh recipient keys after `.sops.yaml` changes
-------------------------------------------------

Run `updatekeys` on each managed secret file:

```sh
cd /etc/nixos/secrets
sops updatekeys -y shared.yaml
sops updatekeys -y obojima-glyph.ttf.json
sops updatekeys -y hosts/jay-framework.yaml
```
