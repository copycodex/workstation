#!/usr/bin/env bash
set -Eeuo pipefail

test_root="$(mktemp -d)"
trap 'chmod 700 "$test_root/home/ExampleOrg/demo-service/locked" 2>/dev/null || true; rm -rf "$test_root"' EXIT
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export WORKSTATION_TEST_NVIM_DIR="$repo_root/nvim"
export WORKSTATION_TEST_CLIPBOARD_PROVIDER="$repo_root/test/nvim-clipboard-provider.lua"
export XDG_CONFIG_HOME="$test_root/config"
export XDG_CACHE_HOME="$test_root/cache"
export XDG_STATE_HOME="$test_root/state"

if [[ $(id -u) == 0 ]]; then
  printf 'EACCES fixture requires a non-root user; uid 0 bypasses directory permissions\n' >&2
  exit 1
fi

mkdir -p \
  "$test_root/fake-bin" \
  "$test_root/empty-bin" \
  "$test_root/project" \
  "$test_root/home/ExampleOrg/demo-service" \
  "$test_root/home/ExampleOrg/demo-service/inner" \
  "$test_root/home/ExampleOrg/demo-service-neighbor" \
  "$test_root/home/.config/exampleorg-demo-service/age" \
  "$test_root/other-project" \
  "$test_root/outside"

# Граница проекта проверяется по реальному расположению файла, поэтому у
# фикстур есть обе стороны симлинка: наружу из проекта и внутрь него.
ln -s "$test_root/outside" "$test_root/home/ExampleOrg/demo-service/escape"
ln -s "$test_root/home/ExampleOrg/demo-service/inner" "$test_root/outside/into-project"
ln -s "$test_root/outside/missing-directory" "$test_root/home/ExampleOrg/demo-service/dangling"
ln -s "$test_root/outside/missing-file.sops.yml" "$test_root/home/ExampleOrg/demo-service/dangling-file.sops.yml"
ln -s loop-b "$test_root/home/ExampleOrg/demo-service/loop-a"
ln -s loop-a "$test_root/home/ExampleOrg/demo-service/loop-b"
mkdir "$test_root/home/ExampleOrg/demo-service/locked"
chmod 000 "$test_root/home/ExampleOrg/demo-service/locked"

cat > "$test_root/fake-bin/sops" <<'SOPS'
#!/usr/bin/env bash
set -Eeuo pipefail

action="$1"
shift
printf '%s|%s|%s\n' "$PWD" "$action" "$*" >> "$SOPS_TEST_LOG"

identity_route=
if [[ -n ${SOPS_TEST_EXAMPLEORG_ROOT:-} && $PWD == "$SOPS_TEST_EXAMPLEORG_ROOT" ]]; then
  if [[ ${SOPS_AGE_KEY_FILE:-} != "$SOPS_TEST_EXAMPLEORG_IDENTITY" || -n ${SOPS_AGE_KEY+x} ]]; then
    printf 'fake sops: wrong ExampleOrg identity environment\n' >&2
    exit 1
  fi
  identity_route=exampleorg
elif [[ -n ${SOPS_TEST_OTHER_ROOT:-} && $PWD == "$SOPS_TEST_OTHER_ROOT" ]]; then
  if [[ ${SOPS_AGE_KEY_FILE:-} != "$SOPS_TEST_INHERITED_KEY_FILE" || ${SOPS_AGE_KEY:-} != "$SOPS_TEST_INHERITED_KEY" ]]; then
    printf 'fake sops: inherited identity environment changed\n' >&2
    exit 1
  fi
  identity_route=inherited
fi
if [[ -n $identity_route ]]; then
  printf 'identity_route|%s|%s\n' "$action" "$identity_route" >> "$SOPS_TEST_LOG"
fi

# Маршрут граничного случая опознаётся по самим переменным identity, а не по
# каталогу: у случаев с симлинками рабочий каталог физический и про место
# вызова ничего не доказывает.
if [[ -n ${SOPS_TEST_CASE:-} ]]; then
  case_route=other
  if [[ ${SOPS_AGE_KEY_FILE:-} == "$SOPS_TEST_EXAMPLEORG_IDENTITY" && -z ${SOPS_AGE_KEY+x} ]]; then
    case_route=exampleorg
  elif [[ ${SOPS_AGE_KEY_FILE:-} == "$SOPS_TEST_INHERITED_KEY_FILE" && ${SOPS_AGE_KEY:-} == "$SOPS_TEST_INHERITED_KEY" ]]; then
    case_route=inherited
  fi
  printf 'identity_case|%s|%s|%s\n' "$action" "$SOPS_TEST_CASE" "$case_route" >> "$SOPS_TEST_LOG"
fi

case "$action" in
  decrypt)
    if grep -q 'FAIL_DECRYPT' "${@: -1}"; then
      printf 'fake sops: decryption key unavailable\n' >&2
      exit 1
    fi
    sed 's/ENC\[AES256_GCM,data:AAAA\]/clear-value/' "${@: -1}"
    ;;
  encrypt)
    if [[ ! -p /dev/stdin ]]; then
      printf 'fake sops: stdin is not a pipe\n' >&2
      exit 1
    fi
    IFS= read -r parent_process < "/proc/$PPID/comm"
    if [[ $parent_process != nvim ]]; then
      printf 'fake sops: parent is %s, expected nvim\n' "$parent_process" >&2
      exit 1
    fi
    printf 'C2_transport|stdin=pipe|parent=%s\n' "$parent_process" >> "$SOPS_TEST_LOG"
    if [[ "${SOPS_TEST_SIGNAL_ENCRYPT:-}" == 1 ]]; then
      sed -n '1s/changed-value/ENC[AES256_GCM,data:PARTIAL]/p' /dev/stdin
      kill -TERM "$$"
    fi
    if [[ "${SOPS_TEST_NONSOPS_ENCRYPT:-}" == 1 ]]; then
      while IFS= read -r _; do :; done < /dev/stdin
      printf 'not a sops document\n'
      exit 0
    fi
    if [[ "${SOPS_TEST_FAIL_ENCRYPT:-}" == 1 ]]; then
      printf 'fake sops: encryption key unavailable\n' >&2
      exit 1
    fi
    if [[ "${SOPS_TEST_EMPTY_ENCRYPT:-}" == 1 ]]; then
      exit 0
    fi
    if [[ "$*" == *'/new.sops.env'* ]]; then
      printf 'fake sops: no creation rules\n' >&2
      exit 1
    fi
    case "$*" in
      *'.sops.json'*|*'.sops.tfvars'*)
        while IFS= read -r _; do :; done < /dev/stdin
        printf '{"secret":"ENC[AES256_GCM,data:CCCC]","sops":{"mac":"ENC[AES256_GCM,data:MAC]"}}\n'
        ;;
      *'.sops.env'*)
        while IFS= read -r _; do :; done < /dev/stdin
        printf 'secret=ENC[AES256_GCM,data:CCCC]\nsops_mac=ENC[AES256_GCM,data:MAC]\n'
        ;;
      *)
        sed -e 's/changed-value/ENC[AES256_GCM,data:CCCC]/' \
          -e 's/clear-value/ENC[AES256_GCM,data:BBBB]/' /dev/stdin
        printf 'sops:\n    mac: ENC[AES256_GCM,data:MAC]\n'
        ;;
    esac
    ;;
  *)
    printf 'fake sops: unexpected action %s\n' "$action" >&2
    exit 2
    ;;
esac
SOPS
chmod +x "$test_root/fake-bin/sops"

cat > "$test_root/fake-bin/d2-unlisted-probe" <<'FORMATTER'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'started\n' >> "$SOPS_TEST_FOREIGN_LOG"
while IFS= read -r line; do
  printf '%s\n' "$line"
done
FORMATTER
chmod +x "$test_root/fake-bin/d2-unlisted-probe"

printf 'secret: ENC[AES256_GCM,data:AAAA]\nsecond: encrypted\n' > "$test_root/project/secrets.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/secrets.SOPS.YML"
printf 'ciphertext: original\n' > "$test_root/project/readonly.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/external.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/missing.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/reload.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/undo.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/lsp.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/late.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/atomic.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/register-write.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/symlink-atomic.sops.yml"
printf 'do not overwrite\n' > "$test_root/project/symlink-victim.txt"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/pipe-transport.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/signalled.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/nonsops.sops.yml"
printf '{"secret":"ENC[AES256_GCM,data:AAAA]"}\n' > "$test_root/project/valid.sops.json"
printf 'secret = "ENC[AES256_GCM,data:AAAA]"\n' > "$test_root/project/valid.sops.tfvars"
printf 'secret=ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/valid.sops.env"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/format.sops.yml"
printf '{"secret":"ENC[AES256_GCM,data:AAAA]"}\n' > "$test_root/project/format.sops.json"
printf 'secret = "ENC[AES256_GCM,data:AAAA]"\n' > "$test_root/project/format.sops.tfvars"
printf 'secret=ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/format.sops.env"
printf '{"ordinary":true}\n' > "$test_root/project/format.json"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/concurrent.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/project/renamed.sops.yml"
printf 'ordinary text\n' > "$test_root/project/ordinary.yml"
printf 'FAIL_DECRYPT\n' > "$test_root/project/broken.sops.yml"
printf 'creation_rules:\n  - path_regex: \\.sops\\.yaml$\n' > "$test_root/project/.sops.yaml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/home/ExampleOrg/demo-service/route.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/other-project/route.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/home/ExampleOrg/demo-service/inner/entered.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/home/ExampleOrg/demo-service-neighbor/route.sops.yml"
printf 'secret: ENC[AES256_GCM,data:AAAA]\n' > "$test_root/outside/escaped.sops.yml"
: > "$test_root/sops.log"
: > "$test_root/foreign.log"

if [[ ${SOPS_TEST_SCENARIO:-all} != concurrent ]]; then
  PATH="$test_root/fake-bin:$PATH" \
    SOPS_TEST_ROOT="$test_root" \
    SOPS_TEST_LOG="$test_root/sops.log" \
    SOPS_TEST_FOREIGN_LOG="$test_root/foreign.log" \
    SOPS_TEST_EXAMPLEORG_ROOT="$test_root/home/ExampleOrg/demo-service" \
    SOPS_TEST_EXAMPLEORG_IDENTITY="$test_root/home/.config/exampleorg-demo-service/age/identity.txt" \
    SOPS_TEST_OTHER_ROOT="$test_root/other-project" \
    SOPS_TEST_OUTSIDE_ROOT="$test_root/outside" \
    SOPS_TEST_INHERITED_KEY_FILE="$test_root/inherited-identity.txt" \
    SOPS_TEST_INHERITED_KEY='synthetic-inherited-key' \
    WORKSTATION_TEST=1 nvim --headless \
      --cmd 'lua vim.opt.runtimepath:prepend(vim.env.WORKSTATION_TEST_NVIM_DIR)' \
      --cmd 'lua dofile(vim.env.WORKSTATION_TEST_CLIPBOARD_PROVIDER)' \
      -u "$repo_root/nvim/init.lua" -l "$repo_root/test/nvim-sops.test.lua"
fi

if [[ ${SOPS_TEST_SCENARIO:-all} != main ]]; then
  barrier="$test_root/concurrent.barrier"
  : > "$barrier"
  writer_pids=()
  for writer in one two; do
    PATH="$test_root/fake-bin:$PATH" \
      SOPS_TEST_ROOT="$test_root" \
      SOPS_TEST_LOG="$test_root/sops.log" \
      SOPS_TEST_WRITER="$writer" \
      SOPS_TEST_BARRIER="$barrier" \
      WORKSTATION_TEST=1 nvim --headless \
        --cmd 'lua vim.opt.runtimepath:prepend(vim.env.WORKSTATION_TEST_NVIM_DIR)' \
        --cmd 'lua dofile(vim.env.WORKSTATION_TEST_CLIPBOARD_PROVIDER)' \
        -u "$repo_root/nvim/init.lua" -l "$repo_root/test/nvim-sops-concurrent-writer.lua" \
      >"$test_root/writer-$writer.out" 2>&1 &
    writer_pids+=("$!")
  done

  writer_statuses=()
  set +e
  for pid in "${writer_pids[@]}"; do
    wait "$pid"
    writer_statuses+=("$?")
  done
  set -e

  if [[ ${writer_statuses[*]} != '0 0' ]]; then
    printf 'concurrent writer statuses: %s\n' "${writer_statuses[*]}" >&2
    sed -n '1,120p' "$test_root"/writer-*.out >&2
    exit 1
  fi
  if compgen -G "$test_root/project/*.sops-nvim-*" >/dev/null; then
    printf 'concurrent writers left temporary files\n' >&2
    exit 1
  fi
  if [[ ${SOPS_TEST_EVIDENCE:-} == 1 ]]; then
    printf 'C1_concurrent_writer_statuses=%s\n' "${writer_statuses[*]}"
    printf 'C1_concurrent_temporary_left=false\n'
  fi
fi

echo 'nvim sops buffer tests: ok'
