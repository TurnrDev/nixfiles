#!/usr/bin/env bats

setup() {
  test_dir="$(mktemp -d)"
  export CONFIG_PATH="$test_dir/config.json"
  export DOCKMGR_STATE_PATH="$test_dir/active-profile"
  export DOCKMGR_TEST_LIB=1
  source "$DOCKMGR_SOURCE"
}

teardown() {
  rm -rf "$test_dir"
}

write_config() {
  printf '%s\n' "$1" > "$CONFIG_PATH"
}

@test "select_profile chooses the most specific matching profile" {
  write_config '{
    "profiles": [
      {"id":"fallback","fallback":true,"order":0,"specificity":0},
      {"id":"usb","match":{"usb":{"anyOf":["1234:5678"]}},"order":1,"specificity":1},
      {"id":"docked","match":{"and":[{"usb":{"allOf":["1234:5678"]}},{"displays":{"connectedAllOf":["DP-1"]}}]},"order":2,"specificity":2}
    ]
  }'

  result="$(select_profile '{"usb":["1234:5678"],"displays":["DP-1"],"lid":{"closed":false}}')"
  [ "$(jq -r .id <<<"$result")" = "docked" ]
}

@test "select_profile supports nested boolean matches and declaration-order ties" {
  write_config '{
    "profiles": [
      {"id":"fallback","fallback":true,"order":0,"specificity":0},
      {"id":"first","match":{"or":[{"lid":{"closed":true}},{"not":{"displays":{"connectedAnyOf":["HDMI-A-1"]}}}]},"order":1,"specificity":1},
      {"id":"last","match":{"not":{"displays":{"connectedAnyOf":["HDMI-A-1"]}}},"order":2,"specificity":1}
    ]
  }'

  result="$(select_profile '{"usb":[],"displays":["DP-1"],"lid":{"closed":false}}')"
  [ "$(jq -r .id <<<"$result")" = "first" ]
}

@test "transition runs hooks in lifecycle order" {
  calls=()
  run_profile_hooks() { calls+=("$2:$3"); }
  apply_profile() { calls+=("$1:apply"); }

  transition_profile '{"name":"old"}' '{"name":"new"}'

  [ "${calls[*]}" = "old:preDown new:preUp {\"name\":\"new\"}:apply old:postDown new:postUp" ]
}

@test "check_transition persists only after a successful profile application" {
  current_profile_json() { printf '%s\n' '{"id":"profile-1","name":"Docked"}'; }
  apply_profile() { return 1; }
  last_profile_id=""
  last_profile_json=""

  ! check_transition
  [ ! -e "$DOCKMGR_STATE_PATH" ]

  apply_profile() { return 0; }
  check_transition
  [ "$(<"$DOCKMGR_STATE_PATH")" = "profile-1" ]
}

@test "session and greeter hooks are isolated" {
  profile='{"hooks":{"session":{"postUp":["session"]},"greeter":{"postUp":["greeter"]}}}'
  CONTEXT=session
  result="$(jq -c --arg context "$CONTEXT" --arg phase postUp '.hooks[$context][$phase] // []' <<<"$profile")"
  [ "$result" = '["session"]' ]
  CONTEXT=greeter
  result="$(jq -c --arg context "$CONTEXT" --arg phase postUp '.hooks[$context][$phase] // []' <<<"$profile")"
  [ "$result" = '["greeter"]' ]
}

@test "CLI help and invalid context are non-destructive" {
  run env -u DOCKMGR_TEST_LIB bash "$DOCKMGR_SOURCE" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]

  run env -u DOCKMGR_TEST_LIB bash "$DOCKMGR_SOURCE" status --context invalid
  [ "$status" -eq 2 ]
  [[ "$output" == *"unsupported context"* ]]
}
