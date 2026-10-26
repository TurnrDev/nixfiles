#!/usr/bin/env bats

script="$BATS_TEST_DIRNAME/../scripts/nixos-build-and-activate.sh"

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
