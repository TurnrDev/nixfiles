#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash nixos-rebuild
# shellcheck shell=bash

build() {
  echo "--------- BEGINNING BUILD FOR $1 ---------"
  local build_host_args=()
  if [ "$1" = "g9-switcher" ]; then
    # nixos-rebuild otherwise builds locally by default; make that explicit so
    # the low-powered target only receives the already-built closure.
    build_host_args=(--build-host "" --use-substitutes)
  fi
  nixos-rebuild switch --show-trace --flake ".#$1" --target-host root@"$1" "${build_host_args[@]}"
  echo "--------- BUILD FINISHED FOR $1 --------"
}

if [ $# -eq 0 ]; then
  HOSTS=(hosts/*)
  HOSTS=("${HOSTS[@]#hosts/}")
else
  HOSTS=("$@")
fi

for arg in "${HOSTS[@]}"; do
  build "$arg"
done

echo "---------- ALL DONE ----------"
