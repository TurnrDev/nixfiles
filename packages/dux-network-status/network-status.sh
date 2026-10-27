#!/usr/bin/env bash

set -u

nm_profiles="$({
  nmcli -t -f NAME,UUID,TYPE,DEVICE connection show 2>/dev/null |
    awk -F: '$3 == "vpn" || $3 == "wireguard"'
} | jq -Rsc '
  split("\n")
  | map(select(length > 0) | split(":")
      | { name: .[0], uuid: .[1], type: .[2], active: ((.[3] // "") != "" and .[3] != "--") })
')"

tailscale_status="$(tailscale status --json 2>/dev/null || printf '{}')"
tailscale_accounts="$(tailscale switch --list --json 2>/dev/null || printf '[]')"

jq -n \
  --argjson networkManager "$nm_profiles" \
  --argjson tailscale "$tailscale_status" \
  --argjson tailnets "$tailscale_accounts" \
  '{
      networkManager: [
        $networkManager[]
      ],
      tailscale: $tailscale,
      tailnets: $tailnets
    }'
