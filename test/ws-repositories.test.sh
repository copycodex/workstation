#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

export HOME="$test_root/home"
export WS_SESSIONS_CONF="$test_root/sessions.conf"

mkdir -p \
  "$HOME/ExampleOrg2/context" \
  "$HOME/ExampleOrg2/demo-service" \
  "$HOME/ExampleOrg2/landing-page" \
  "$HOME/ExampleOrg2/brand"

printf '%s\n' \
  'EX2-term home ~/ExampleOrg2 shell' \
  '@repo EX2 ~/ExampleOrg2 demo-service' \
  '@repo EX2 ~/ExampleOrg2 landing-page' \
  '@repo EX2 ~/ExampleOrg2 brand' \
  '@repo EX2 ~/ExampleOrg2 pto-agents' \
  > "$WS_SESSIONS_CONF"

# shellcheck source=bin/ws
source "$repo_root/bin/ws"

expected_rendered="$(printf '%s\n' \
  'EX2-term home ~/ExampleOrg2 shell' \
  'EX2-term demo-service ~/ExampleOrg2/demo-service term if-dir' \
  'EX2-code demo-service ~/ExampleOrg2/demo-service edit if-dir' \
  'EX2-term landing-page ~/ExampleOrg2/landing-page term if-dir' \
  'EX2-code landing-page ~/ExampleOrg2/landing-page edit if-dir' \
  'EX2-term brand ~/ExampleOrg2/brand term if-dir' \
  'EX2-code brand ~/ExampleOrg2/brand edit if-dir' \
  'EX2-term pto-agents ~/ExampleOrg2/pto-agents term if-dir' \
  'EX2-code pto-agents ~/ExampleOrg2/pto-agents edit if-dir')"
actual_rendered="$(config_rows)"

[[ $actual_rendered == "$expected_rendered" ]] || {
  printf 'FAIL: @repo expansion differs\nexpected:\n%s\nactual:\n%s\n' \
    "$expected_rendered" "$actual_rendered" >&2
  exit 1
}

expected_term="$(printf '%s\n' \
  'home ~/ExampleOrg2 shell' \
  'demo-service ~/ExampleOrg2/demo-service term' \
  'landing-page ~/ExampleOrg2/landing-page term' \
  'brand ~/ExampleOrg2/brand term')"
actual_term="$(windows_of EX2-term 2>"$test_root/warnings")"

[[ $actual_term == "$expected_term" ]] || {
  printf 'FAIL: available repository windows differ\nexpected:\n%s\nactual:\n%s\n' \
    "$expected_term" "$actual_term" >&2
  exit 1
}

expected_code="$(printf '%s\n' \
  'demo-service ~/ExampleOrg2/demo-service edit' \
  'landing-page ~/ExampleOrg2/landing-page edit' \
  'brand ~/ExampleOrg2/brand edit')"
actual_code="$(windows_of EX2-code 2>"$test_root/code-warnings")"

[[ $actual_code == "$expected_code" ]] || {
  printf 'FAIL: code repository windows differ\nexpected:\n%s\nactual:\n%s\n' \
    "$expected_code" "$actual_code" >&2
  exit 1
}

grep -qxF \
  "ws: нет каталога $HOME/ExampleOrg2/pto-agents — окно EX2-term:pto-agents пропущено" \
  "$test_root/warnings"
grep -qxF \
  "ws: нет каталога $HOME/ExampleOrg2/pto-agents — окно EX2-code:pto-agents пропущено" \
  "$test_root/code-warnings"

printf 'ws repository composition: OK\n'
