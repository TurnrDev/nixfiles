#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq nixpkgs#nix nixpkgs#gnused --command bash
# shellcheck shell=bash

set -euo pipefail

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_file="$package_dir/default.nix"
releases_url="https://api.github.com/repos/sharpemu/sharpemu/releases?per_page=100"

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
    jq -er '
        [
          .[]
          | select(.draft | not)
          | . as $release
          | ($release.tag_name | sub("^v"; "")) as $version
          | $release.assets[]
          | select(.name == "sharpemu-\($version)-linux-x64.tar.gz")
          | {
              releaseTag: $release.tag_name,
              url: .browser_download_url
            }
        ][0]
      '
)"

latest_release_tag="$(jq -er '.releaseTag' <<<"$release")"
source_url="$(jq -er '.url' <<<"$release")"
latest_hash="$(
  nix hash convert --hash-algo sha256 --to base16 \
    "$(nix-prefetch-url --type sha256 "$source_url")"
)"

current_release_tag="$(sed -nE 's/^[[:space:]]*releaseTag = "([^"]+)";/\1/p' "$package_file")"
current_hash="$(sed -nE 's/^[[:space:]]*sha256 = "([^"]+)";/\1/p' "$package_file")"

printf 'Current SharpEmu release: %s\n' "$current_release_tag"
printf 'Latest SharpEmu release:  %s\n' "$latest_release_tag"

if [[ $current_release_tag == "$latest_release_tag" && $current_hash == "$latest_hash" ]]; then
  echo "SharpEmu is already up to date"
  exit 0
fi

sed -i -E \
  -e "s|^([[:space:]]*)releaseTag = \"[^\"]+\";|\\1releaseTag = \"$latest_release_tag\";|" \
  -e "s|^([[:space:]]*)sha256 = \"[^\"]+\";|\\1sha256 = \"$latest_hash\";|" \
  "$package_file"

updated_release_tag="$(sed -nE 's/^[[:space:]]*releaseTag = "([^"]+)";/\1/p' "$package_file")"
updated_hash="$(sed -nE 's/^[[:space:]]*sha256 = "([^"]+)";/\1/p' "$package_file")"

if [[ $updated_release_tag != "$latest_release_tag" || $updated_hash != "$latest_hash" ]]; then
  echo "Failed to update $package_file" >&2
  exit 1
fi

printf 'Updated SharpEmu to %s (%s)\n' "$latest_release_tag" "$latest_hash"
