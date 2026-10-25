#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$HOME/.config"
export GIT_MR_ASSIGNEE=sample-user
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
unset GIT_CONFIG_GLOBAL
unset GIT_CONFIG_COUNT
for config_var in ${!GIT_CONFIG_KEY_@} ${!GIT_CONFIG_VALUE_@}; do
  unset "$config_var"
done
mkdir -p "$HOME"
"$ROOT/install/link.sh" >/dev/null
for file in config mr.conf mr.sh; do
  [[ -L "$XDG_CONFIG_HOME/git/$file" ]]
  [[ $(readlink -f "$XDG_CONFIG_HOME/git/$file") == "$ROOT/git/$file" ]]
done

if [[ ${1:-} == --negative ]]; then
  cat >"$HOME/.gitconfig" <<'EOF'
[push]
	pushOption = merge_request.assign=sample-user
EOF
fi

make_remote() {
  local remote="$1"
  git init --bare -q "$remote"
  git -C "$remote" config receive.advertisePushOptions true
  cat >"$remote/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log="$(dirname -- "$0")/../push-options.log"
printf 'count=%s\n' "${GIT_PUSH_OPTION_COUNT:-0}" >>"$log"
for ((i = 0; i < ${GIT_PUSH_OPTION_COUNT:-0}; i++)); do
  name="GIT_PUSH_OPTION_$i"
  printf '%s\n' "${!name}" >>"$log"
done
EOF
  chmod +x "$remote/hooks/pre-receive"
}

make_repo() {
  local repo="$1" remote="$2"
  mkdir -p "$(dirname -- "$repo")"
  git init -q -b main "$repo"
  git -C "$repo" remote add origin "$remote"
  git -C "$repo" checkout -q -b feature/test
  git -C "$repo" commit -q --allow-empty -m first
}

assert_last_options() {
  local log="$1" expected="$2" actual
  actual=$(cat "$log")
  if [[ $actual != "$expected" ]]; then
    printf 'push options mismatch: expected %q, got %q\n' "$expected" "$actual" >&2
    return 1
  fi
}

check_inside() {
  local root="$1" title="$2" remote repo log output before expected
  remote="$TEST_ROOT/$root.git"
  repo="$HOME/$root/project"
  log="$remote/push-options.log"
  make_remote "$remote"
  make_repo "$repo" "$remote"
  git -C "$repo" config --get alias.mr >/dev/null

  git -C "$repo" push -q origin HEAD:refs/heads/feature/test
  assert_last_options "$log" 'count=0'

  git -C "$repo" commit -q --allow-empty -m second
  : >"$log"
  if [[ -n $title ]]; then
    git -C "$repo" mr "$title" >/dev/null
  else
    git -C "$repo" mr >/dev/null
  fi
  expected=$'count=4\nmerge_request.create\nmerge_request.target=main\nmerge_request.remove_source_branch\nmerge_request.assign=sample-user'
  if [[ -n $title ]]; then
    expected+=$'\n'"merge_request.title=$title"
    expected=${expected/count=4/count=5}
  fi
  assert_last_options "$log" "$expected"

  before=$(cat "$log")
  if output=$(git -C "$repo" mr 2>&1); then
    echo 'repeated git mr unexpectedly succeeded' >&2
    return 1
  fi
  [[ $output == *'branch is already pushed'* ]]
  [[ $(cat "$log") == "$before" ]]
}

check_inside ExampleOrg ''
check_inside ExampleOrg2 'A title with spaces'

echo 'git-workspace: ok'
