#!/usr/bin/env bash

set -o errexit
set -o pipefail

usage() {
  cat <<'EOF'
Usage: nixos-build-and-activate [OPTIONS]

Build the NixOS configuration, show its nvd diff, then optionally activate it.

Options:
  -s, --skip-update       Do not run `nix flake update` before building.
  -a, --action ACTION     Activate non-interactively using: switch/s, boot/b,
                          test/t, or cancel/c.
  -H, --host HOST         NixOS configuration name (default: local hostname).
  -t, --target-host HOST  Activate on HOST over SSH. Passed to
                          `nixos-rebuild --target-host`.
  -b, --build-host HOST   Build on HOST over SSH. Passed to
                          `nixos-rebuild --build-host`; use the same host as
                          --target-host to build and activate remotely.
  -h, --help              Show this help text.
EOF
}

normalize_action() {
  case "$1" in
  switch | s)
    printf 'switch\n'
    ;;
  boot | b)
    printf 'boot\n'
    ;;
  test | t | "")
    printf 'test\n'
    ;;
  cancel | c)
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
target_host=""
build_host=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  -s | --skip-update)
    skip_update=true
    ;;
  -a | --action)
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
  -H | --host)
    if [[ $# -lt 2 ]]; then
      printf '%s requires a host name.\n' "$1" >&2
      exit 2
    fi
    host="$2"
    shift
    ;;
  --host=*)
    host="${1#*=}"
    ;;
  -t | --target-host)
    if [[ $# -lt 2 ]]; then
      printf '%s requires an SSH host.\n' "$1" >&2
      exit 2
    fi
    target_host="$2"
    shift
    ;;
  --target-host=*)
    target_host="${1#*=}"
    ;;
  -b | --build-host)
    if [[ $# -lt 2 ]]; then
      printf '%s requires an SSH host.\n' "$1" >&2
      exit 2
    fi
    build_host="$2"
    shift
    ;;
  --build-host=*)
    build_host="${1#*=}"
    ;;
  -h | --help)
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

flake=".#nixosConfigurations.${host}.config.system.build.toplevel"

if [[ -n $action ]]; then
  if ! action="$(normalize_action "$action")"; then
    printf 'Unknown action: %s\n' "$action" >&2
    exit 2
  fi
fi

cd /etc/nixos

if [[ $skip_update != true ]]; then
  sudo nix flake update --flake ./packages/dockmgr
  sudo nix flake update
fi

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

if ! nix eval "${flake}.drvPath" --raw >/dev/null; then
  printf 'No NixOS configuration found for host: %s\n' "$host" >&2
  exit 1
fi

if [[ -z $target_host && -z $build_host ]]; then
  nix build "$flake" --show-trace --out-link "$build_dir/result"
  nvd diff /run/current-system "$build_dir/result"
else
  printf 'Skipping local build preview; nixos-rebuild will use the requested SSH host(s).\n'
fi

if [[ -z $action ]]; then
  printf 'Activate this build? [s]witch/[b]oot/[T]est/[c]ancel '
  read -r action
  action="$(normalize_action "$action")"
fi

rebuild_args=("$action" --flake . --show-trace)
if [[ -n $target_host ]]; then
  rebuild_args+=(--target-host "$target_host")
fi
if [[ -n $build_host ]]; then
  rebuild_args+=(--build-host "$build_host")
fi

case "$action" in
switch | boot | test)
  if [[ -n $target_host ]]; then
    nixos-rebuild "${rebuild_args[@]}"
  else
    sudo nixos-rebuild "${rebuild_args[@]}"
  fi
  ;;
cancel | "")
  exit 0
  ;;
*)
  printf 'Unknown action: %s\n' "$action" >&2
  exit 1
  ;;
esac

sudo nix-env --delete-generations 7d
