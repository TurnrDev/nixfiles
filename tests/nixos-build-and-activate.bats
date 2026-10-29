#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../scripts/nixos-build-and-activate.sh"

setup() {
  mock_bin="$BATS_TEST_TMPDIR/bin"
  command_log="$BATS_TEST_TMPDIR/commands"
  COMMAND_LOG="$command_log"
  mkdir -p "$mock_bin" "$BATS_TEST_TMPDIR/candidate" "$BATS_TEST_TMPDIR/remote-system"
  : > "$command_log"

  cat > "$mock_bin/nix" <<'EOF'
#!/usr/bin/env bash
printf 'nix %s\n' "$*" >> "$COMMAND_LOG"
case "$1" in
  eval)
    ;;
  build)
    shift
    while [[ $# -gt 0 ]]; do
      if [[ $1 == --out-link ]]; then
        ln -s "$BATS_TEST_TMPDIR/candidate" "$2"
        break
      fi
      shift
    done
    ;;
esac
EOF

  cat > "$mock_bin/nix-shell" <<'EOF'
#!/usr/bin/env bash
printf 'nix-shell %s\n' "$*" >> "$COMMAND_LOG"
while [[ $# -gt 0 && $1 != --run ]]; do
  shift
done
shift
exec bash -c "$1"
EOF

  cat > "$mock_bin/nvd" <<'EOF'
#!/usr/bin/env bash
printf 'nvd %s\n' "$*" >> "$COMMAND_LOG"
EOF

  cat > "$mock_bin/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'ssh %s\n' "$*" >> "$COMMAND_LOG"
if [[ $* == *'readlink -f /run/current-system'* ]]; then
  printf '%s\n' "$BATS_TEST_TMPDIR/remote-system"
fi
EOF

  cat > "$mock_bin/nixos-rebuild" <<'EOF'
#!/usr/bin/env bash
printf 'nixos-rebuild %s\n' "$*" >> "$COMMAND_LOG"
if [[ $1 == build ]]; then
  ln -s "$BATS_TEST_TMPDIR/candidate" result
fi
EOF

  cat > "$mock_bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "$COMMAND_LOG"
"$@"
EOF

  cat > "$mock_bin/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
printf 'nix-collect-garbage %s\n' "$*" >> "$COMMAND_LOG"
EOF

  chmod +x "$mock_bin"/*
  export BATS_TEST_TMPDIR COMMAND_LOG
  export PATH="$mock_bin:$PATH"
}

@test "activation script prints help without evaluating or activating a system" {
  run bash "$script" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: nixos-build-and-activate"* ]]
  [[ "$output" == *"--target-host HOST"* ]]
  [[ "$output" == *"--build-host HOST"* ]]
}

@test "activation script rejects an unknown action before performing work" {
  run bash "$script" --action unsupported

  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown action"* ]]
}

@test "activation script validates missing remote host arguments before performing work" {
  run bash "$script" --target-host

  [ "$status" -eq 2 ]
  [[ "$output" == *"requires an SSH host"* ]]
}

@test "remote activation previews the remote system and deploys the exact local candidate" {
  run bash "$script" --skip-update --action switch --host g9-switcher --target-host root@g9-switcher

  [ "$status" -eq 0 ]
  grep -F 'nix build .#nixosConfigurations.g9-switcher.config.system.build.toplevel --show-trace --out-link' "$command_log"
  grep -F 'ssh root@g9-switcher readlink -f /run/current-system' "$command_log"
  grep -F "nix copy --from ssh-ng://root@g9-switcher $BATS_TEST_TMPDIR/remote-system" "$command_log"
  grep -F "nvd diff $BATS_TEST_TMPDIR/remote-system" "$command_log"
  grep -F "nixos-rebuild switch --store-path $BATS_TEST_TMPDIR/candidate --no-reexec --show-trace --target-host root@g9-switcher" "$command_log"
  grep -F 'ssh root@g9-switcher nix-collect-garbage --delete-older-than 7d' "$command_log"
}

@test "remote build host builds the local flake before remote deployment" {
  run bash "$script" --skip-update --action test --host g9-switcher --build-host jay@builder --target-host root@g9-switcher

  [ "$status" -eq 0 ]
  grep -F 'nixos-rebuild build --flake /etc/nixos#g9-switcher --build-host jay@builder --show-trace' "$command_log"
  grep -F "nixos-rebuild test --store-path $BATS_TEST_TMPDIR/candidate --no-reexec --show-trace --target-host root@g9-switcher" "$command_log"
  ! grep -F 'nix-collect-garbage' "$command_log"
}

@test "cancel performs no update, build, preview, deployment, or cleanup" {
  run bash "$script" --action cancel

  [ "$status" -eq 0 ]
  [ ! -s "$command_log" ]
}

@test "remote sudo requires a remote target" {
  run bash "$script" --action test --remote-sudo

  [ "$status" -eq 2 ]
  [[ "$output" == *"--remote-sudo requires --target-host"* ]]
}
