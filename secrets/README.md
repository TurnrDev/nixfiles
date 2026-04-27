SOPS secrets layout
===================

This repo uses two scopes for secrets:

- `shared.yaml`: same secret values for multiple machines.
- `hosts/<hostname>.yaml`: host-specific values.

`.sops.yaml` lives in this directory, so run commands from `/etc/nixos/secrets`:

```sh
cd /etc/nixos/secrets
```

If `sops` is not installed globally, use:

```sh
nix shell nixpkgs#sops --command sops <args...>
```

Key setup (required once per machine)
-------------------------------------

This repo uses `age1...` recipients generated from SSH public keys. For editing
with `sops`, create a local age private key file from your SSH private key:

```sh
mkdir -p ~/.config/sops/age
nix shell nixpkgs#ssh-to-age --command ssh-to-age \
  -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Then export it in your shell:

```sh
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

Optional persistent setup:

```sh
echo 'export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"' >> ~/.zshrc
```

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

GitHub API rate limits for Nix flakes
-------------------------------------

Nix needs GitHub credentials before it can evaluate this flake, so the token
cannot be bootstrapped from a SOPS-managed NixOS secret. Store it in a local
root-only Nix config include instead:

```sh
sudo install -d -m 0755 /etc/nix
printf 'access-tokens = github.com=ghp_example\n' \
  | sudo tee /etc/nix/github-access-token.conf >/dev/null
sudo chmod 0600 /etc/nix/github-access-token.conf
```

Replace `ghp_example` with a GitHub personal access token. The shared NixOS
role includes this file with `!include`, so machines without it keep working.
For the first rebuild, before that include has been activated, either put the
same `access-tokens = ...` line in `~/.config/nix/nix.conf` temporarily or run
the rebuild with:

```sh
sudo env NIX_CONFIG='access-tokens = github.com=ghp_example' nixos-rebuild switch --flake /etc/nixos
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

1. Add the host SSH public key at `../hosts/<hostname>/id_ed25519.pub`.
2. Convert it to an age recipient:
   `ssh-to-age < ../hosts/<hostname>/id_ed25519.pub`
3. Add it to `.sops.yaml` keys and creation rules.
4. Create/edit `hosts/<hostname>.yaml` with `sops`.
5. Refresh recipient metadata:
   `sops updatekeys -y hosts/<hostname>.yaml`

Refresh recipient keys after `.sops.yaml` changes
-------------------------------------------------

Run `updatekeys` on each managed secret file:

```sh
cd /etc/nixos/secrets
sops updatekeys -y shared.yaml
sops updatekeys -y hosts/jay-framework.yaml
```
