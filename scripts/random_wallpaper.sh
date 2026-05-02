#!/usr/bin/env bash

set -euo pipefail

query="${1:-}"


hyprctl monitors -j | jq -r '.[] | "\(.name) \(.width) \(.height)"' | while read -r name width height; do
    echo "$name $width $height"
    file="$(mktemp /tmp/wallpaper."${name}".XXX.jpg)"

    if [[ -n "$query" ]]; then
      response="$(curl -fsSL --get \
        --data-urlencode "q=${query}" \
        --data "sorting=random" \
        --data "purity=100" \
        --data "atleast=${width}x${height}" \
        "https://wallhaven.cc/api/v1/search")"
    else
      response="$(curl -fsSL --get \
        --data "sorting=random" \
        --data "purity=100" \
        --data "atleast=${width}x${height}" \
        "https://wallhaven.cc/api/v1/search")"
    fi
    url="$(jq -r '.data[0].path // empty' <<<"$response")"
    if [[ -z "$url" ]]; then
        echo "Wallhaven returned no URL for ${width}x${height}. API response:" >&2
        echo "$response" >&2
        continue
    fi

    curl -fsSL --output "$file" "$url"
    magick "$file" -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" "$file"
    dms ipc call wallpaper setFor "$name" "$file"
done
