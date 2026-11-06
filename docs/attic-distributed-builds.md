# Private Attic cache and distributed builds

## Architecture

Every NixOS host uses the private `home` Attic cache at
`https://attic.infra.turnr.net/home`, verifies
`home:UZTl/gEUbtCPZdJgPOUAC0CO0dBNndyk0dOOf73vCGA=`, and retains its existing
substituters including `cache.nixos.org`. Attic's cache priority is 41, just
behind `cache.nixos.org` at 40. Nix falls back to other substituters or source
builds when the private cache is unreachable.

The daemon reads a root-only SOPS-rendered netrc at `/run/secrets/attic-netrc`.
The token is its Basic Auth password, never a Nix-store value. The same scoped
read/write token intentionally serves all hosts; it must have only `r` and `w`
for cache `home`, never cache creation, destruction, configuration, or
retention permissions.

| Host | Local jobs | Accepts remote jobs | Remote builders | Cache upload |
| --- | ---: | --- | --- | --- |
| jay-desktop | 12 | yes | none | yes |
| jay-framework | 6 | yes | jay-desktop | yes |
| jay-mopo | 4 | no | jay-desktop, jay-framework | yes |
| g9-switcher | 0 | no | none | no |
| home-server | not yet NixOS | planned fallback | n/a | planned |

`jay-desktop` remains local-only as a builder and `jay-framework` delegates in
one direction to it. This avoids cyclic delegation. `jay-mopo` is a client
only: it can build locally or offload but does not create the restricted remote
builder account. All builder links use the SOPS runtime private key; the public
client key is declarative at `keys/authorized/nix-remote-builder.pub`, and host
keys are in `keys/known_hosts/nix-builders`. The target account is restricted to
`nix-store --serve --write`, with forwarding and interactive access disabled.

## Uploading and offline behaviour

Attic's native `watch-store` is intentionally not used. It only observes store
events while it is running and has no persistent offline queue, so paths built
while it cannot connect can be missed. Instead, Nix's post-build hook appends
only newly-built output paths to a root-only local spool. `attic-upload.service`
uses native `attic push` asynchronously, and its path unit plus persistent
five-minute timer retry after network loss or reboot. `attic push` checks the
cache and honours Attic's upstream-key filter, avoiding uploads already signed
by `cache.nixos.org`.

The hook does not run for substituted paths. A path garbage-collected before a
later retry is dropped from the spool; build or retain it again if it must be
published. This is a durable retry queue, not a full-store synchronizer.

Useful checks:

```sh
systemctl status attic-upload.path attic-upload.timer attic-upload.service
sudo cat /var/lib/attic-upload/pending
journalctl -u attic-upload.service
nix show-config | rg 'substituters|netrc-file|builders|builders-use-substitutes'
```

## Remote-build operations

Use `nix store info --json` or Nix build logs to see the selected remote
builder. `nix show-config | rg '^builders'` shows the generated machine list.
If an optional builder is offline, the five-second connection timeout lets Nix
continue with the next machine or local work where eligible.

Nix's `speedFactor` is advisory scheduling input, not a strict failover or
capacity guarantee. When `home-server` has migrated to NixOS, import
`modules/nixos/roles/nix-builder.nix`, set its `maxJobs = 1` and
`remoteBuilder.enable = true`, then add `"home-server"` last in the relevant
`builders` lists. Its low `speedFactor` and one job reduce load but cannot
guarantee it is never selected.

To add another builder, add its fixed capacity and speed in
`modules/nixos/services/distributed-builds.nix`, record its verified host key
in `keys/known_hosts/nix-builders`, enable its restricted remote account, and
add its name after the preferred builders on clients. Generate a replacement
key/token for a suspected compromise and follow the rotation sequence in
`secrets/README.md`.

## g9-switcher deployment

`deploy.sh g9-switcher` explicitly passes an empty `--build-host`, so
`nixos-rebuild` builds on the initiating desktop/Framework (or that machine's
eligible remote builders), transfers the closure, and activates remotely.
`--use-substitutes` lets g9 fetch cache members when beneficial, but direct
closure copying remains available and Attic need not contain every output.

`max-jobs = 0` prevents ordinary local building on g9. Nix can still honour a
derivation marked `preferLocalBuild`; therefore the deployment rule above is
important and operators should not invoke `nixos-rebuild` directly on g9.

## Security limitation

SOPS decrypts `shared.yaml` for every configured recipient. Runtime file modes
limit normal service access, but they do not isolate fields cryptographically:
any configured host recipient can decrypt the shared Attic token and builder
key. Use separate recipient-scoped files if that trust boundary changes.
