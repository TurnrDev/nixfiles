#!/usr/bin/env bash

set -euo pipefail

kind="$1"
target="$2"
state="$3"

case "$kind" in
  networkmanager)
    if [ "$state" = "active" ]; then
      exec nmcli connection down uuid "$target"
    fi
    exec nmcli connection up uuid "$target"
    ;;
  tailscale)
    if [ "$state" = "active" ]; then
      exec tailscale down
    fi
    exec tailscale up
    ;;
  tailnet)
    exec tailscale switch "$target"
    ;;
  *)
    exit 2
    ;;
esac
