#!/usr/bin/env bash

set -eu

target="$1"
backup="$target.hm-backup"

if [ ! -e "$backup" ]; then
  exec mv -- "$target" "$backup"
fi

i=1
while [ -e "$backup.$i" ]; do
  i=$((i + 1))
done

exec mv -- "$target" "$backup.$i"
