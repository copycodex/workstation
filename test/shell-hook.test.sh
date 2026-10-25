#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

if grep -q 'WORKSTATION_MIGRATE_LEGACY_AGENTS' "$ROOT/install/shell-hook.sh"; then
  mkdir -p "$TEST_ROOT/public-default"
  printf "alias codex-dev='keep-me'\n" > "$TEST_ROOT/public-default/.bashrc"
  HOME="$TEST_ROOT/public-default" "$ROOT/install/shell-hook.sh" >/dev/null
  grep -qxF "alias codex-dev='keep-me'" "$TEST_ROOT/public-default/.bashrc"
  export WORKSTATION_MIGRATE_LEGACY_AGENTS=1
fi

TEST_HOME="$TEST_ROOT/home"
TEST_BIN="$TEST_ROOT/vendor-bin"
AGENT_BIN="$TEST_ROOT/dev-agents/bin"
mkdir -p "$TEST_HOME/bin" "$TEST_BIN" "$AGENT_BIN"

assert_invalid_blocks() {
  local bashrc="$1" home before output
  home="$(dirname -- "$bashrc")"
  before="$bashrc.before"
  cp -- "$bashrc" "$before"

  if output=$(HOME="$home" "$ROOT/install/shell-hook.sh" 2>&1); then
    printf 'shell-hook accepted invalid block structure in %s\n' "$bashrc" >&2
    return 1
  fi
  [[ $output == *'некорректные блоки'* ]]
  cmp -s -- "$before" "$bashrc"
}

BROKEN_HOME="$TEST_ROOT/broken-home"
mkdir -p "$BROKEN_HOME"
cat >"$BROKEN_HOME/.bashrc" <<'EOF'
# >>> workstation ws >>>
keep this tail
EOF
assert_invalid_blocks "$BROKEN_HOME/.bashrc"

EXTRA_BEGIN_HOME="$TEST_ROOT/extra-begin-home"
mkdir -p "$EXTRA_BEGIN_HOME"
cat >"$EXTRA_BEGIN_HOME/.bashrc" <<'EOF'
alias codex-dev='/must/stay/until/preflight/passes'
# >>> dev-agents launchers >>>
complete block
# <<< dev-agents launchers <<<
keep this tail
# >>> dev-agents launchers >>>
EOF
assert_invalid_blocks "$EXTRA_BEGIN_HOME/.bashrc"

REVERSED_HOME="$TEST_ROOT/reversed-home"
mkdir -p "$REVERSED_HOME"
cat >"$REVERSED_HOME/.bashrc" <<'EOF'
# <<< workstation ws <<<
keep this middle
# >>> workstation ws >>>
EOF
assert_invalid_blocks "$REVERSED_HOME/.bashrc"

DUPLICATE_HOME="$TEST_ROOT/duplicate-home"
mkdir -p "$DUPLICATE_HOME"
cat >"$DUPLICATE_HOME/.bashrc" <<'EOF'
# >>> workstation ws >>>
first block
# <<< workstation ws <<<
# >>> workstation ws >>>
second block
# <<< workstation ws <<<
EOF
assert_invalid_blocks "$DUPLICATE_HOME/.bashrc"

INTERLEAVED_HOME="$TEST_ROOT/interleaved-home"
mkdir -p "$INTERLEAVED_HOME"
cat >"$INTERLEAVED_HOME/.bashrc" <<'EOF'
# >>> workstation ws >>>
# >>> dev-agents launchers >>>
keep this middle
# <<< workstation ws <<<
# <<< dev-agents launchers <<<
EOF
assert_invalid_blocks "$INTERLEAVED_HOME/.bashrc"

LEGACY_ALIAS_BLOCK_HOME="$TEST_ROOT/legacy-alias-block-home"
mkdir -p "$LEGACY_ALIAS_BLOCK_HOME"
cat >"$LEGACY_ALIAS_BLOCK_HOME/.bashrc" <<'EOF'
# >>> dev-agents launchers >>>
alias codex-dev='/old/codex-developer.sh'
alias claude-own='/old/claude-owner.sh'
# <<< dev-agents launchers <<<
EOF
HOME="$LEGACY_ALIAS_BLOCK_HOME" DEV_AGENTS_BIN="$AGENT_BIN" \
  "$ROOT/install/shell-hook.sh" >/dev/null
grep -qxF "# alias codex-dev='/old/codex-developer.sh'" \
  "$LEGACY_ALIAS_BLOCK_HOME/.bashrc"
grep -qxF "# alias claude-own='/old/claude-owner.sh'" \
  "$LEGACY_ALIAS_BLOCK_HOME/.bashrc"
[[ $(grep -cxF '# >>> dev-agents launchers >>>' \
  "$LEGACY_ALIAS_BLOCK_HOME/.bashrc") == 1 ]]

MISSING_HOME="$TEST_ROOT/missing-home"
MISSING_LAUNCHERS="$TEST_ROOT/missing-launchers"
mkdir -p "$MISSING_HOME/bin"
: >"$MISSING_HOME/.bashrc"
ln -s "$MISSING_LAUNCHERS/codex-developer.sh" "$MISSING_HOME/bin/codex-dev"
HOME="$MISSING_HOME" DEV_AGENTS_BIN="$MISSING_LAUNCHERS" \
  "$ROOT/install/shell-hook.sh" >/dev/null
[[ -L $MISSING_HOME/bin/codex-dev ]]

META_HOME="$TEST_ROOT/meta-home"
META_MARKER="$TEST_ROOT/path-injection-ran"
META_BIN="$TEST_ROOT/dev-agents-\$literal-\$(mark-path-injection)-\`mark-path-injection\`-\"quoted path\"/bin"
mkdir -p "$META_HOME" "$META_BIN"
: >"$META_HOME/.bashrc"
cat >"$TEST_BIN/mark-path-injection" <<'EOF'
#!/bin/sh
: >"$PATH_INJECTION_MARKER"
EOF
chmod +x "$TEST_BIN/mark-path-injection"

HOME="$META_HOME" DEV_AGENTS_BIN="$META_BIN" \
  "$ROOT/install/shell-hook.sh" >/dev/null
printf -v quoted_meta_bin '%q' "$META_BIN"
grep -qxF "export PATH=$quoted_meta_bin:\$PATH" "$META_HOME/.bashrc"
meta_output="$(
  HOME="$META_HOME" PATH="$TEST_BIN:/usr/bin:/bin" \
    PATH_INJECTION_MARKER="$META_MARKER" \
    bash --noprofile --rcfile "$META_HOME/.bashrc" -ic \
      'printf "%s\n" "${PATH%%:*}"' 2>&1 \
    | sed '/cannot set terminal process group/d; /no job control in this shell/d'
)"
[[ $meta_output == "$META_BIN" ]]
[[ ! -e $META_MARKER ]]

UNSAFE_ALIAS_HOME="$TEST_ROOT/unsafe-alias-home"
mkdir -p "$UNSAFE_ALIAS_HOME"
cat >"$UNSAFE_ALIAS_HOME/.bashrc" <<'EOF'
# keep unsafe aliases byte-for-byte
alias codex-dev='/roles/developer'; export KEEP=1
alias claude-own='/roles/'\
'owner'
EOF
unsafe_output="$(HOME="$UNSAFE_ALIAS_HOME" DEV_AGENTS_BIN="$AGENT_BIN" \
  "$ROOT/install/shell-hook.sh" 2>&1)"
[[ $(sed -n '2p' "$UNSAFE_ALIAS_HOME/.bashrc") == \
  "# alias codex-dev='/roles/developer'; export KEEP=1" ]]
[[ $(sed -n '3p' "$UNSAFE_ALIAS_HOME/.bashrc") == \
  "# alias claude-own='/roles/'\\" ]]
[[ $unsafe_output == *'закомментирован старый alias codex-dev: строки 2'* ]]
[[ $unsafe_output == *'закомментирован старый alias claude-own: строки 3'* ]]

REMAINDER_HOME="$TEST_ROOT/remainder-home"
mkdir -p "$REMAINDER_HOME"
cat >"$REMAINDER_HOME/.bashrc" <<'EOF'
export KEEP=1; alias codex-dev='/nested/developer'
export KEEP_TOO=1; claude() { command claude "$@"; }
EOF
remainder_output="$(HOME="$REMAINDER_HOME" DEV_AGENTS_BIN="$AGENT_BIN" \
  "$ROOT/install/shell-hook.sh")"
[[ $(sed -n '1p' "$REMAINDER_HOME/.bashrc") == \
  "export KEEP=1; alias codex-dev='/nested/developer'" ]]
[[ $(sed -n '2p' "$REMAINDER_HOME/.bashrc") == \
  'export KEEP_TOO=1; claude() { command claude "$@"; }' ]]
[[ $remainder_output == *"1:export KEEP=1; alias codex-dev='/nested/developer'"* ]]
[[ $remainder_output == *'2:export KEEP_TOO=1; claude() { command claude "$@"; }'* ]]

cat >"$TEST_HOME/.bashrc" <<'EOF'
# keep me
alias codex-dev='/outside/codex-developer.sh'
  alias claude-own='/outside/claude-owner.sh'
# >>> dev-agents launchers >>>
codex() {
  command codex "$@"
}

claude() {
  command claude "$@"
}
# <<< dev-agents launchers <<<
EOF

for command_name in codex claude; do
  cat >"$TEST_BIN/$command_name" <<EOF
#!/usr/bin/env bash
printf 'vendor $command_name:'
if (( \$# )); then
  printf ' <%s>' "\$@"
fi
printf '\nidentity: none\n'
EOF
  chmod +x "$TEST_BIN/$command_name"
done

cat >"$AGENT_BIN/ccx" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == own && ${2:-} == --acc && ${3:-} == demo ]]; then
  printf '%s\n' 'ccx: unsupported entry: role=own model=opus account=demo' >&2
  exit 1
fi

case ${1:-} in
  dev)
    printf '%s\n' \
      'role: developer' \
      'account: example-developer' \
      'author: AI Developer <developer@example.test>' \
      'instance: git.example.invalid' \
      'transport: https://example-developer@git.example.invalid/example/workstation.git'
    ;;
  own)
    printf '%s\n' \
      'role: owner' \
      'account: example-reviewer' \
      'author: unassigned <unassigned>' \
      'instance: git.example.invalid' \
      'transport: https://git.example.invalid/example/workstation.git'
    ;;
  *) exit 2 ;;
esac

printf 'argv:'
printf ' <%s>' "$@"
printf '\n'
EOF
chmod +x "$AGENT_BIN/ccx"

for launcher in codex-developer.sh claude-owner.sh; do
  printf '#!/bin/sh\nexit 99\n' >"$AGENT_BIN/$launcher"
  chmod +x "$AGENT_BIN/$launcher"
done

ln -s "$AGENT_BIN/codex-developer.sh" "$TEST_HOME/bin/codex-dev"
ln -s "$AGENT_BIN/claude-owner.sh" "$TEST_HOME/bin/claude-own"

install_output="$(HOME="$TEST_HOME" DEV_AGENTS_BIN="$AGENT_BIN" "$ROOT/install/shell-hook.sh")"
HOME="$TEST_HOME" DEV_AGENTS_BIN="$AGENT_BIN" "$ROOT/install/shell-hook.sh" >/dev/null

run_shell() {
  local output status

  if output="$(HOME="$TEST_HOME" PATH="$TEST_HOME/bin:$TEST_BIN:/usr/bin:/bin" \
    bash --noprofile --rcfile "$TEST_HOME/.bashrc" -ic "$1" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  printf '%s\n' "$output" \
    | sed '/cannot set terminal process group/d; /no job control in this shell/d'
  return "$status"
}

assert_shell_failure() {
  local command="$1" expected="$2" output status

  if output="$(run_shell "$command")"; then
    printf 'shell command unexpectedly succeeded: %s\n' "$command" >&2
    return 1
  else
    status=$?
  fi

  [[ $status -ne 0 ]]
  [[ $output == "$expected" ]]
}

[[ $(grep -cxF '# >>> dev-agents launchers >>>' "$TEST_HOME/.bashrc") == 1 ]]
if grep -qE '^[[:space:]]*alias[[:space:]]+codex-dev=' "$TEST_HOME/.bashrc"; then exit 1; fi
if grep -qE '^[[:space:]]*alias[[:space:]]+claude-own=' "$TEST_HOME/.bashrc"; then exit 1; fi
if grep -qE '^[[:space:]]*(codex|claude)[[:space:]]*\(\)[[:space:]]*\{' \
  "$TEST_HOME/.bashrc"; then exit 1; fi
grep -qxF '# # >>> dev-agents launchers >>>' "$TEST_HOME/.bashrc"
grep -qxF '# codex() {' "$TEST_HOME/.bashrc"
grep -qxF '# claude() {' "$TEST_HOME/.bashrc"
[[ $install_output == *'закомментирован старый alias codex-dev: строки 2'* ]]
[[ $install_output == *'закомментирован старый alias claude-own: строки 3'* ]]
[[ $install_output == *'закомментирован старый блок входов codex/claude: строки 4-12'* ]]
printf -v quoted_agent_bin '%q' "$AGENT_BIN"
grep -qxF "export PATH=$quoted_agent_bin:\$PATH" "$TEST_HOME/.bashrc"
[[ ! -e $TEST_HOME/bin/codex-dev ]]
[[ ! -e $TEST_HOME/bin/claude-own ]]

[[ $(run_shell 'type -t codex') == file ]]
[[ $(run_shell 'type -t claude') == file ]]
[[ $(run_shell 'type -t ccx') == file ]]
[[ $(run_shell 'codex') == $'vendor codex:\nidentity: none' ]]
[[ $(run_shell 'claude') == $'vendor claude:\nidentity: none' ]]
[[ $(run_shell 'claude --dev') == $'vendor claude: <--dev>\nidentity: none' ]]
[[ $(run_shell 'codex --dev') == $'vendor codex: <--dev>\nidentity: none' ]]
[[ $(run_shell 'ccx dev exec -- --own') == $'role: developer\naccount: example-developer\nauthor: AI Developer <developer@example.test>\ninstance: git.example.invalid\ntransport: https://example-developer@git.example.invalid/example/workstation.git\nargv: <dev> <exec> <--> <--own>' ]]
[[ $(run_shell 'ccx own') == $'role: owner\naccount: example-reviewer\nauthor: unassigned <unassigned>\ninstance: git.example.invalid\ntransport: https://git.example.invalid/example/workstation.git\nargv: <own>' ]]

assert_shell_failure 'ccx own --acc demo' \
  'ccx: unsupported entry: role=own model=opus account=demo'
[[ $(run_shell 'type -t codex-dev || true') == '' ]]
[[ $(run_shell 'type -t claude-own || true') == '' ]]

printf 'shell-hook: ok\n'
