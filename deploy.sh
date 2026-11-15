#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash nixos-rebuild
# shellcheck shell=bash
set -e

build() {
  echo "--------- BEGINNING BUILD FOR $1 ---------"
  nixos-rebuild switch --show-trace --flake ".#$1" --target-host "jay@$1" --sudo --ask-sudo-password
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
