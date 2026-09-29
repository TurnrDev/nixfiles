# Migrate Borg passphrases per host

Use one `storagebox-borg-passphrase` value per host. On that host, the same
value protects both Hetzner Borg 1.4 repositories and the OVH Borg 2
repository. Never reuse that value on another host.

The Nix configuration already implements this design: both borgmatic configs
read `storagebox-borg-passphrase` from `secrets/hosts/<hostname>.yaml`. No
module or secret-name change is required. This runbook changes the values that
were previously reused across hosts.

Run the procedure independently on each host. Do not print either passphrase or
put an unencrypted passphrase in Git.

## What the migration changes

- Borg 2: rewrap the existing repository key with the new host passphrase.
- Borg 1.4: create new repositories with new encryption keys, recreate every
  archived backup in them, verify the migration, and delete the old
  repositories.
- SOPS: replace the host's `storagebox-borg-passphrase` value and refresh all
  three exported repository keys.

An in-place passphrase change is suitable for this planned separation because
the old shared passphrase is not assumed to be exposed. It does not replace a
repository encryption key. If the old passphrase or a repository key may have
been exposed, follow [Compromise changes the procedure](#compromise-changes-the-procedure).

## 1. Check the current backups and stop the timer

Create and check one final backup with the current passphrase. Omit the Borg 2
commands if this host's Borg 2 prefix has not been initialized yet.

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND BORG_REPO
unset BORG_NEW_PASSPHRASE BORG_NEW_PASSPHRASE_FD BORG_NEW_PASSCOMMAND

borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" create
borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" check
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" create
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" check
```

Stop scheduled backups for the entire migration window:

```sh
systemctl --user stop borgmatic.timer borgmatic.service
test "$(systemctl --user is-active borgmatic.service)" = inactive
```

## 2. Stage the old and new passphrases

Copy the currently rendered secret into the per-user runtime directory and
generate a new 256-bit value. This directory is normally memory-backed and is
removed at logout:

```sh
migration_directory="${XDG_RUNTIME_DIR:?}/borg-passphrase-migration"
old_passphrase_file="$migration_directory/old"
new_passphrase_file="$migration_directory/new"

install -d -m 700 "$migration_directory"
install -m 600 \
  "$HOME/.config/sops-nix/secrets/storagebox-borg-passphrase" \
  "$old_passphrase_file"
(umask 077; nix shell nixpkgs#openssl --command openssl rand -hex 32 \
  | tr -d '\n' >"$new_passphrase_file")
```

Keep this shell open until the migration is complete; later commands use these
variables.

Keep an encrypted migration copy of the old value in the host's SOPS file. It
is needed to read the old archives until every one has been recreated and
verified:

```sh
host_name="$(hostname)"

jq -Rs 'rtrimstr("\n")' <"$old_passphrase_file" \
  | (cd /etc/nixos/secrets && \
      sops set --value-stdin \
        "hosts/${host_name}.yaml" \
        '["storagebox-borg-migration-passphrase"]')
```

That temporary SOPS key is deliberately not declared in the Nix module, so it
is not rendered as a normal runtime secret.

## 3. Rewrap the Borg 2 key

Use `BORG_PASSCOMMAND` for the old value and `BORG_NEW_PASSCOMMAND` for the new
value. Clear other passphrase variables first; Borg refuses ambiguous sources.

If this host's Borg 2 prefix has not been initialized, skip this step. Step 4
includes the alternative initialization command.

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND
unset BORG_NEW_PASSPHRASE BORG_NEW_PASSPHRASE_FD BORG_NEW_PASSCOMMAND

export AWS_SHARED_CREDENTIALS_FILE="$HOME/.config/sops-nix/secrets/rendered/ovh-borg2-aws-credentials"
export AWS_DEFAULT_REGION=gra
export AWS_REGION=gra

BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
BORG_NEW_PASSCOMMAND="cat ${new_passphrase_file}" \
  borg2 key change-passphrase \
    --repo "s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}"
```

Do not proceed unless this succeeds. Keep both temporary files until the whole
archive migration and verification are complete.

## 4. Install the new host passphrase

Replace the existing value under the same key name:

```sh
jq -Rs 'rtrimstr("\n")' <"$new_passphrase_file" \
  | (cd /etc/nixos/secrets && \
      sops set --value-stdin \
        "hosts/${host_name}.yaml" \
        '["storagebox-borg-passphrase"]')

sudo nixos-rebuild switch --flake "/etc/nixos#${host_name}"
```

Confirm that the rendered value is the new value without displaying it:

```sh
cmp -s \
  "$new_passphrase_file" \
  "$HOME/.config/sops-nix/secrets/storagebox-borg-passphrase"
```

Then verify access to Borg 2 with the normal borgmatic configuration:

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND BORG_REPO
unset BORG_NEW_PASSPHRASE BORG_NEW_PASSPHRASE_FD BORG_NEW_PASSCOMMAND
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" repo-info
```

If the Borg 2 prefix did not exist and step 3 was skipped, initialize it now
instead:

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND
unset BORG_NEW_PASSPHRASE BORG_NEW_PASSPHRASE_FD BORG_NEW_PASSCOMMAND
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.config/sops-nix/secrets/rendered/ovh-borg2-aws-credentials"
export AWS_DEFAULT_REGION=gra
export AWS_REGION=gra

BORG_REPO="s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}" \
BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
  borg2 repo-create \
    --encryption aes256-ocb \
    --id-hash blake3 \
    --key-location repokey
```

## 5. Move the old Borg 1.4 repositories aside temporarily

The old repositories must temporarily move because the fresh repositories need
their original paths. Give both source repositories the same dated suffix.
Hetzner's restricted SSH shell supports `mv` on port 23.

```sh
migration_id="$(date -u +%Y%m%dT%H%M%SZ)"
source_name="${host_name}.migration-source-${migration_id}"

ssh -i "$HOME/.ssh/id_ed25519" -o IdentitiesOnly=yes -p 23 \
  u551190@u551190.your-storagebox.de \
  mv "$host_name" "$source_name"

ssh -i "$HOME/.ssh/id_ed25519" -o IdentitiesOnly=yes -p 23 \
  u650719@u650719.your-storagebox.de \
  mv "$host_name" "$source_name"

fsn1_source="ssh://u551190@u551190.your-storagebox.de:23/./${source_name}"
fsn1_destination="ssh://u551190@u551190.your-storagebox.de:23/./${host_name}"
hel1_source="ssh://u650719@u650719.your-storagebox.de:23/./${source_name}"
hel1_destination="ssh://u650719@u650719.your-storagebox.de:23/./${host_name}"

# The repository IDs are unchanged but their paths intentionally moved.
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
```

These renamed repositories are migration sources, not long-term rollback
copies. They still require the old passphrase and will be deleted only after
their archive inventories match the new repositories and restore tests pass.

## 6. Initialize fresh Borg 1.4 repositories

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_REPO
export BORG_PASSCOMMAND="cat ${new_passphrase_file}"
export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"

borg init \
  --remote-path borg-1.4 \
  --encryption repokey-blake2 \
  "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}"

borg init \
  --remote-path borg-1.4 \
  --encryption repokey-blake2 \
  "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}"
```

These commands generate a different encryption key for each repository. Both
keys are protected by this host's new shared passphrase.

## 7. Recreate every archived backup in the new repositories

Borg 1.4 cannot transfer archives directly between repositories. To replace
the encryption keys, every archive must be read with the old key and written
again with the new key. The following function extracts one archive at a time
and recreates it with the same name, start timestamp, and comment. Data flows
through this host and is re-encrypted before upload.

Choose a local staging filesystem with enough free space for the largest
uncompressed archive. It must support the file metadata you need to preserve,
including ACLs and extended attributes. Do not put it below `$HOME`, because
that is itself a backup source.

```sh
export BORG_MIGRATION_STAGE_ROOT=/path/to/private/staging-filesystem
test -d "$BORG_MIGRATION_STAGE_ROOT"
test -w "$BORG_MIGRATION_STAGE_ROOT"
```

Run the migration once for each Storage Box:

```sh
(
  set -euo pipefail

  archived_home="${HOME#/}"
  export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"
  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND BORG_REPO

  migrate_archives() (
    set -euo pipefail

    source_repository="$1"
    destination_repository="$2"
    label="$3"
    migration_work="$(mktemp -d \
      --tmpdir="${BORG_MIGRATION_STAGE_ROOT:?}" \
      "borg-${label}.XXXXXX")"
    archive_manifest="$migration_work/archives.json"
    archive_names="$migration_work/archive-names"
    archive_stage="$migration_work/archive"
    trap 'rm -rf -- "$migration_work"' EXIT

    BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
      borg list --remote-path borg-1.4 --json "$source_repository" \
      >"$archive_manifest"
    jq -r '.archives[].archive' "$archive_manifest" >"$archive_names"

    while IFS= read -r archive_name; do
      if BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
        borg info --remote-path borg-1.4 \
          "${destination_repository}::${archive_name}" >/dev/null 2>&1
      then
        printf 'Already present in %s: %s\n' "$label" "$archive_name"
        continue
      fi

      archive_info="$(
        BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
          borg info --remote-path borg-1.4 --json \
            "${source_repository}::${archive_name}"
      )"
      archive_time="$(jq -r '.archives[0].start' <<<"$archive_info")"
      archive_time="${archive_time%%.*}"
      archive_comment="$(jq -r '.archives[0].comment // ""' \
        <<<"$archive_info")"

      rm -rf -- "$archive_stage"
      install -d -m 700 "$archive_stage"

      (
        cd "$archive_stage"
        BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
          borg extract --remote-path borg-1.4 --sparse \
            "${source_repository}::${archive_name}"
        test -e "$archived_home"
        BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
          borg create --remote-path borg-1.4 \
            --atime \
            --files-cache disabled \
            --timestamp "$archive_time" \
            --comment "$archive_comment" \
            "${destination_repository}::${archive_name}" \
            "$archived_home"
      )

      rm -rf -- "$archive_stage"
      printf 'Migrated to %s: %s\n' "$label" "$archive_name"
    done <"$archive_names"
  )

  migrate_archives "$fsn1_source" "$fsn1_destination" hetzner-fsn1
  migrate_archives "$hel1_source" "$hel1_destination" hetzner-hel1
)
```

The destination deduplicates recreated archives, but every source archive still
has to be downloaded and examined. The process is resumable: archives already
present in the destination are skipped. If it stops, leave the old repository
and passphrase in place and run it again.

This is not a byte-for-byte archive copy. Borg 1.4 has no direct transfer
operation, so archive IDs, creation command metadata, and ctime will change.
Archive names, start timestamps, comments, paths, contents, permissions, ACLs,
and extended attributes are retained where the staging filesystem supports
them. Borg's tar import/export route is not used because it explicitly loses
ACLs and extended attributes; see the
[Borg 1.4 tar documentation](https://borgbackup.readthedocs.io/en/stable/usage/tar.html).

## 8. Verify the migration and create a current backup

Compare archive names and start timestamps between each temporary source and
its destination. Repository and archive IDs are expected to differ.

```sh
(
  set -euo pipefail

  comparison_directory="$(mktemp -d \
    --tmpdir="${XDG_RUNTIME_DIR:?}" borg-inventory.XXXXXX)"
  trap 'rm -rf -- "$comparison_directory"' EXIT

  compare_inventories() {
    source_repository="$1"
    destination_repository="$2"
    label="$3"

    BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
      borg list --remote-path borg-1.4 --json "$source_repository" \
      | jq -S '[.archives[] | {name: .archive, start}] | sort_by(.name, .start)' \
      >"$comparison_directory/${label}-source.json"

    BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
      borg list --remote-path borg-1.4 --json "$destination_repository" \
      | jq -S '[.archives[] | {name: .archive, start}] | sort_by(.name, .start)' \
      >"$comparison_directory/${label}-destination.json"

    diff -u \
      "$comparison_directory/${label}-source.json" \
      "$comparison_directory/${label}-destination.json"
  }

  compare_inventories "$fsn1_source" "$fsn1_destination" hetzner-fsn1
  compare_inventories "$hel1_source" "$hel1_destination" hetzner-hel1
)
```

An empty `diff` is success. Then perform full cryptographic data verification
on both new repositories. This can take a long time because `--verify-data`
downloads and decrypts all archive data:

```sh
BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
  borg check --remote-path borg-1.4 --verify-data "$fsn1_destination"
BORG_PASSCOMMAND="cat ${new_passphrase_file}" \
  borg check --remote-path borg-1.4 --verify-data "$hel1_destination"
```

Perform restore tests from several old and recent archives in both new
repositories. Restore into a temporary directory, never over the live source.

Finally, let borgmatic create and check a current backup in all three
destinations using the installed passphrase:

```sh
unset BORG_PASSPHRASE BORG_PASSPHRASE_FD BORG_PASSCOMMAND BORG_REPO
unset BORG_NEW_PASSPHRASE BORG_NEW_PASSPHRASE_FD BORG_NEW_PASSCOMMAND

borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" create
borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" check
borgmatic --config "$HOME/.config/borgmatic.d/borg1.4.yaml" repo-info

borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" create
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" check
borgmatic --config "$HOME/.config/borgmatic.d/borg2.yaml" repo-info
```

## 9. Refresh all exported repository keys

The Borg 1.4 repositories now have new keys. The Borg 2 key itself is unchanged,
but its exported form must be refreshed because it is now wrapped by the new
passphrase.

```sh
(
  set -euo pipefail

  unset BORG_PASSPHRASE BORG_PASSPHRASE_FD
  export BORG_PASSCOMMAND="cat ${new_passphrase_file}"
  export BORG_RSH="ssh -i ${HOME}/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 23"

  key_file="$(mktemp --tmpdir="${XDG_RUNTIME_DIR:?}" borg-key.XXXXXX)"
  trap 'rm -f "$key_file"' EXIT

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u551190@u551190.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$key_file"
  jq -Rs . <"$key_file" \
    | (cd /etc/nixos/secrets && \
        sops set --value-stdin "hosts/${host_name}.yaml" \
          '["hetzner-fsn1-borg1.4-repokey"]')

  borg key export \
    --remote-path borg-1.4 \
    "ssh://u650719@u650719.your-storagebox.de:23/./${host_name}" \
    /dev/stdout >"$key_file"
  jq -Rs . <"$key_file" \
    | (cd /etc/nixos/secrets && \
        sops set --value-stdin "hosts/${host_name}.yaml" \
          '["hetzner-hel1-borg1.4-repokey"]')

  borg2 key export \
    --repo "s3:https://s3.gra.io.cloud.ovh.net/borg-2/${host_name}" \
    /dev/stdout >"$key_file"
  jq -Rs . <"$key_file" \
    | (cd /etc/nixos/secrets && \
        sops set --value-stdin "hosts/${host_name}.yaml" \
          '["ovh-borg2-repokey"]')
)
```

Commit the updated encrypted host file. Verify that both the host identity and
the break-glass recovery identity can decrypt it, as described in
[`disaster-recovery.md`](../disaster-recovery.md).

## 10. Delete the old repositories and resume backups

This is the irreversible step. Do it only after all of the following are true:

1. Both inventory comparisons produced an empty diff.
2. Both new repositories passed `borg check --verify-data`.
3. Restore tests from old and recent migrated archives passed.
4. The current borgmatic backup completed successfully.
5. The three new exported keys are safely stored in SOPS and recoverable.

Print and inspect the exact two source URLs before deleting anything:

```sh
printf 'Delete migration source only: %s\n' \
  "$fsn1_source" \
  "$hel1_source"
```

If both paths end in the expected `${source_name}`, delete those repositories:

```sh
BORG_DELETE_I_KNOW_WHAT_I_AM_DOING=YES \
BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
  borg delete --remote-path borg-1.4 "$fsn1_source"

BORG_DELETE_I_KNOW_WHAT_I_AM_DOING=YES \
BORG_PASSCOMMAND="cat ${old_passphrase_file}" \
  borg delete --remote-path borg-1.4 "$hel1_source"
```

The archives now exist only in the newly encrypted repositories. Remove the
temporary old passphrase from SOPS and the plaintext migration files:

```sh
cd /etc/nixos/secrets
sops unset "hosts/$(hostname).yaml" \
  '["storagebox-borg-migration-passphrase"]'

rm -f "$old_passphrase_file" "$new_passphrase_file"
rmdir "$migration_directory"
unset old_passphrase_file new_passphrase_file migration_directory
unset fsn1_source fsn1_destination hel1_source hel1_destination source_name
unset BORG_MIGRATION_STAGE_ROOT
unset BORG_RELOCATED_REPO_ACCESS_IS_OK BORG_DELETE_I_KNOW_WHAT_I_AM_DOING
```

Resume scheduled backups:

```sh
systemctl --user start borgmatic.timer
systemctl --user list-timers borgmatic.timer --no-pager
```

## Roll back

Rollback is possible only before step 10 deletes the migration sources. Stop
the timer, move each failed new Borg 1.4 repository to a new diagnostic name,
move its `${source_name}` directory back to `${host_name}`, restore
`storagebox-borg-passphrase` from the retained old value, and rebuild. Change
the Borg 2 key passphrase back with the old/new passcommands reversed. Verify
all repository access before restarting the timer.

Do not delete either generation while diagnosing a failed migration.

## Compromise changes the procedure

If a passphrase and an exported repository key may both have been exposed, an
in-place passphrase change is insufficient: the existing repository key can
still decrypt old and future data in that repository. Create a fresh Borg 2
repository/prefix as well as fresh Borg 1.4 repositories, complete and verify
new backups, then revoke access to the old locations. Previously copied backup
data cannot be made confidential again.

See the compromise procedure in
[`disaster-recovery.md`](../disaster-recovery.md#respond-to-an-exposed-private-key).
Borg documents the limitation for both versions:

- [Borg 1.4 key documentation](https://borgbackup.readthedocs.io/en/stable/usage/key.html#borg-key-change-passphrase)
- [Borg 2 key documentation](https://borgbackup.readthedocs.io/en/latest/usage/key.html#borg-key-change-passphrase)

Hetzner documents port 23, explicit Borg remote versions, and the restricted
shell's `mv` support in its
[Storage Box SSH and Borg documentation](https://docs.hetzner.com/storage/storage-box/access/access-ssh-rsync-borg/).
