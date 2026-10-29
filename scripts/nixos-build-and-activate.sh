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
  -t, --target-host HOST  Activate the previewed system on HOST over SSH.
  -b, --build-host HOST   Build the local flake on HOST over SSH, then copy the
                          resulting candidate back for preview and deployment.
      --remote-sudo       Use sudo to activate and clean up on a non-root
                          --target-host.
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

ensure_dependencies() {
  if [[ -n ${NIXOS_BUILD_AND_ACTIVATE_IN_NIX_SHELL:-} ]]; then
    return
  fi

  local script_path quoted_script quoted_args
  script_path="$(readlink -f "${BASH_SOURCE[0]}")"
  printf -v quoted_script '%q' "$script_path"
  printf -v quoted_args ' %q' "$@"

  exec nix-shell -p nix nvd openssh --run \
    "NIXOS_BUILD_AND_ACTIVATE_IN_NIX_SHELL=1 bash ${quoted_script}${quoted_args}"
}

original_args=("$@")
skip_update=false
action=""
host="$(hostname)"
target_host=""
build_host=""
remote_sudo=false

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
  --remote-sudo)
    remote_sudo=true
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

if [[ $action == cancel ]]; then
  exit 0
fi

if [[ $remote_sudo == true && -z $target_host ]]; then
  printf '%s requires --target-host.\n' "--remote-sudo" >&2
  exit 2
fi

ensure_dependencies "${original_args[@]}"

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

candidate_link="$build_dir/result"
if [[ -n $build_host ]]; then
  (
    cd "$build_dir"
    nixos-rebuild build --flake "/etc/nixos#${host}" --build-host "$build_host" --show-trace
  )
else
  nix build "$flake" --show-trace --out-link "$candidate_link"
fi

candidate_system="$(readlink -f "$candidate_link")"

current_system="/run/current-system"
if [[ -n $target_host ]]; then
  remote_system="$(ssh "$target_host" 'readlink -f /run/current-system')"
  nix copy --from "ssh-ng://${target_host}" "$remote_system"
  current_system="$remote_system"
fi

nvd diff "$current_system" "$build_dir/result"

if [[ -z $action ]]; then
  printf 'Activate this build? [s]witch/[b]oot/[T]est/[c]ancel '
  read -r action
  if ! action="$(normalize_action "$action")"; then
    printf 'Unknown action: %s\n' "$action" >&2
    exit 2
  fi
fi

# Use the exact store path that was just built and previewed. This prevents a
# second evaluation/build from changing what reaches the activation target.
rebuild_args=("$action" --store-path "$candidate_system" --no-reexec --show-trace)
if [[ -n $target_host ]]; then
  rebuild_args+=(--target-host "$target_host")
fi
if [[ $remote_sudo == true ]]; then
  rebuild_args+=(--elevate sudo)
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

if [[ $action == switch || $action == boot ]]; then
  if [[ -n $target_host ]]; then
    if [[ $remote_sudo == true ]]; then
      ssh "$target_host" 'sudo nix-collect-garbage --delete-older-than 7d'
    else
      ssh "$target_host" 'nix-collect-garbage --delete-older-than 7d'
    fi
  else
    sudo nix-collect-garbage --delete-older-than 7d
  fi
fi
