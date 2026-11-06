SOPS secrets
============

All secret files are encrypted for the root-owned OpenSSH host key on each
machine. To edit a file, convert this machine's root key to a temporary age
identity and load it into the current shell:

```sh
cd /etc/nixos/secrets
export SOPS_AGE_KEY_FILE="${XDG_RUNTIME_DIR:?}/sops-root-age-key.txt"
(
  umask 077
  nix shell nixpkgs#ssh-to-age --command sh -c \
    'sudo "$(command -v ssh-to-age)" -private-key -i /etc/ssh/ssh_host_ed25519_key' \
    >"$SOPS_AGE_KEY_FILE"
)
```

`SOPS_AGE_KEY_FILE` is an age identity derived from the root key; it is not the
root key itself. It is kept in the per-user runtime directory, which is
normally memory-backed and removed at logout. Remove it when finished:

```sh
rm -f "$SOPS_AGE_KEY_FILE"
unset SOPS_AGE_KEY_FILE
```

Edit secrets
------------

Run `sops` with the path you want to edit:

```sh
sops shared.yaml
sops hosts/"$(hostname)".yaml
```

`shared.yaml` contains values used by more than one machine. Files under
`hosts/` contain machine-specific values.

If `sops` is not installed globally, use `nix shell nixpkgs#sops --command`
instead, preserving the loaded identity:

```sh
nix shell nixpkgs#sops --command sops shared.yaml
```

Recipient changes
-----------------

When `.sops.yaml` changes, rewrap every affected secret file:

```sh
sops updatekeys -y shared.yaml
sops updatekeys -y obojima-glyph.ttf.json
sops updatekeys -y hosts/"$(hostname)".yaml
```

New-host setup and recovery procedures are documented in
[NEW_HOST_SETUP.md](../NEW_HOST_SETUP.md) and
[disaster-recovery.md](../disaster-recovery.md).
