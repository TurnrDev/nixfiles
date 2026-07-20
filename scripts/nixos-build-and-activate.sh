#!/usr/bin/env bash

set -o errexit
set -o pipefail

usage() {
  cat <<'EOF'
Usage: nixos-build-and-activate [--skip-update] [--action ACTION]

Build the NixOS configuration, show its nvd diff, then optionally activate it.

Options:
  -s, --skip-update       Do not run `nix flake update` before building.
  -a, --action ACTION     Activate non-interactively using: switch/s, boot/b,
                          test/t, or cancel/c.
  -h, --help              Show this help text.
EOF
}

normalize_action() {
  case "$1" in
    switch|s)
      printf 'switch\n'
      ;;
    boot|b)
      printf 'boot\n'
      ;;
    test|t|"")
      printf 'test\n'
      ;;
    cancel|c)
      printf 'cancel\n'
      ;;
    *)
      return 1
      ;;
  esac
}

skip_update=false
action=""
host="$(hostname)"
flake=".#nixosConfigurations.${host}.config.system.build.toplevel"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--skip-update)
      skip_update=true
      ;;
    -a|--action)
      if [[ $# -lt 2 ]]; then
        printf '%s requires an action.\n' "$1" >&2
        exit 2
      fi
      action="$2"
      shift
      ;;
    --action=*)
      action="${1#*=}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ -n "$action" ]]; then
  if ! action="$(normalize_action "$action")"; then
    printf 'Unknown action: %s\n' "$action" >&2
    exit 2
  fi
fi

cd /etc/nixos

if [[ "$skip_update" != true ]]; then
  sudo nix flake update
fi

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

if ! nix eval "${flake}.drvPath" --raw >/dev/null; then
  printf 'No NixOS configuration found for host: %s\n' "$host" >&2
  exit 1
fi

nix build "$flake" --show-trace --out-link "$build_dir/result"
nvd diff /run/current-system "$build_dir/result"

if [[ -z "$action" ]]; then
  printf 'Activate this build? [s]witch/[b]oot/[T]est/[c]ancel '
  read -r action
  action="$(normalize_action "$action")"
fi

case "$action" in
  switch|boot|test)
    sudo nixos-rebuild "$action" --flake . --show-trace
    ;;
  cancel|"")
    exit 0
    ;;
  *)
    printf 'Unknown action: %s\n' "$action" >&2
    exit 1
    ;;
esac

sudo nix-env --delete-generations 7d
