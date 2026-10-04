#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq nixpkgs#nix nixpkgs#gnused --command bash
# shellcheck shell=bash

set -euo pipefail

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_file="$package_dir/default.nix"
manifest_url="https://gitlab.com/es-de/emulationstation-de/-/raw/master/latest_release.json"

manifest="$(curl --fail --silent --show-error --location "$manifest_url")"
latest_version="$(jq -er '.stable.version' <<<"$manifest")"
source_url="$(
  jq -er '.stable.packages[] | select(.name == "LinuxAppImage") | .url' <<<"$manifest"
)"
latest_hash="$(
  nix hash convert --hash-algo sha256 --to base16 \
    "$(nix-prefetch-url --type sha256 "$source_url")"
)"

current_version="$(sed -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$package_file")"
current_hash="$(sed -nE 's/^[[:space:]]*sha256 = "([^"]+)";/\1/p' "$package_file")"

printf 'Current ES-DE version: %s\n' "$current_version"
printf 'Latest ES-DE version:  %s\n' "$latest_version"

if [[ $current_version == "$latest_version" && $current_hash == "$latest_hash" ]]; then
  echo "ES-DE is already up to date"
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

printf 'Updated ES-DE to %s (%s)\n' "$latest_version" "$latest_hash"
