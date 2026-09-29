#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq nixpkgs#nix nixpkgs#gnused --command bash
# shellcheck shell=bash

set -euo pipefail

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_file="$package_dir/default.nix"
asset_name="borg-linux-glibc239-x86_64-gh"
releases_url="https://api.github.com/repos/borgbackup/borg/releases?per_page=100"

curl_args=(
  --fail
  --silent
  --show-error
  --location
  --header "Accept: application/vnd.github+json"
  --header "X-GitHub-Api-Version: 2022-11-28"
)

if [[ -n ${GITHUB_TOKEN:-} ]]; then
  curl_args+=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

release="$(
  curl "${curl_args[@]}" "$releases_url" |
    jq -er --arg asset "$asset_name" '
        [
          .[]
          | select(.draft | not)
          | select(.tag_name | test("^v?2\\."))
          | . as $release
          | $release.assets[]
          | select(.name == $asset)
          | {
              version: ($release.tag_name | sub("^v"; "")),
              url: .browser_download_url
            }
        ][0]
      '
)"

latest_version="$(jq -er '.version' <<<"$release")"
source_url="$(jq -er '.url' <<<"$release")"
latest_hash="$(
  nix hash convert --hash-algo sha256 --to base16 \
    "$(nix-prefetch-url --type sha256 "$source_url")"
)"

current_version="$(sed -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file")"
current_hash="$(sed -nE 's/^[[:space:]]*sha256 = "([^"]+)";/\1/p' "$package_file")"

printf 'Current Borg 2 version: %s\n' "$current_version"
printf 'Latest Borg 2 version:  %s\n' "$latest_version"

if [[ $current_version == "$latest_version" && $current_hash == "$latest_hash" ]]; then
  echo "borgbackup is already up to date"
  exit 0
fi

sed -i -E \
  -e "s|^([[:space:]]*)version = \"[^\"]+\";|\\1version = \"$latest_version\";|" \
  -e "s|^([[:space:]]*)sha256 = \"[^\"]+\";|\\1sha256 = \"$latest_hash\";|" \
  "$package_file"

updated_version="$(sed -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file")"
updated_hash="$(sed -nE 's/^[[:space:]]*sha256 = "([^"]+)";/\1/p' "$package_file")"

if [[ $updated_version != "$latest_version" || $updated_hash != "$latest_hash" ]]; then
  echo "Failed to update $package_file" >&2
  exit 1
fi

printf 'Updated borgbackup to %s (%s)\n' "$latest_version" "$latest_hash"
