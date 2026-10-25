#!/usr/bin/env bash
# Ставит в ~/.bashrc блоки, которые нельзя разложить симлинком:
#   * вопрос «Открыть tmux?» при запуске интерактивного терминала;
#   * команда ccx из dev-agents в PATH.
#
# Отдельным шагом, а не частью `make link`, потому что правит ~/.bashrc —
# файл пользователя, а не конфиг из репозитория.
#
# Повторный запуск заменяет свои блоки целиком, а не пропускает установку:
# их содержимое меняется вместе с `ws` и со входом dev-agents, и «уже
# стоит» оставило бы в ~/.bashrc устаревший вызов.
set -euo pipefail

BASHRC="$HOME/.bashrc"
DEV_AGENTS_BIN="${DEV_AGENTS_BIN:-}"
WS_MARK_BEGIN='# >>> workstation ws >>>'
WS_MARK_END='# <<< workstation ws <<<'
AGENTS_MARK_BEGIN='# >>> dev-agents launchers >>>'
AGENTS_MARK_END='# <<< dev-agents launchers <<<'

# Пустые строки в хвосте съедаем перед дописыванием: без этого каждый повторный
# запуск оставлял бы после удалённого блока ещё одну пустую строку.
trim_trailing_blank_lines() {
  sed -i -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' "$BASHRC"
}

# До первой правки одним проходом проверяем все четыре маркера. Допустимы
# только отсутствующие либо одиночные, упорядоченные и непересекающиеся пары.
validate_blocks() {
  local structure
  local wc wl wx wz ac al ax az

  structure="$(awk \
    -v wb="$WS_MARK_BEGIN" -v we="$WS_MARK_END" \
    -v ab="$AGENTS_MARK_BEGIN" -v ae="$AGENTS_MARK_END" '
      $0 == wb { wc++; wl = NR }
      $0 == we { wx++; wz = NR }
      $0 == ab { ac++; al = NR }
      $0 == ae { ax++; az = NR }
      END { print wc + 0, wl + 0, wx + 0, wz + 0,
                  ac + 0, al + 0, ax + 0, az + 0 }
    ' "$BASHRC")"
  read -r wc wl wx wz ac al ax az <<<"$structure"

  if (( ! ((wc == 0 && wx == 0) || (wc == 1 && wx == 1 && wl < wz)) ||
        ! ((ac == 0 && ax == 0) || (ac == 1 && ax == 1 && al < az)) ||
        (wc == 1 && ac == 1 && ! (wz < al || az < wl)) )); then
    printf 'некорректные блоки в %s: ws=%s:%s-%s:%s, dev-agents=%s:%s-%s:%s\n' \
      "$BASHRC" "$wc" "$wl" "$wx" "$wz" "$ac" "$al" "$ax" "$az" >&2
    return 1
  fi
}

# Заменяет проверенный блок между маркерами или дописывает его в конец файла.
install_block() {
  local begin="$1" end="$2" body="$3" action

  if grep -qxF -- "$begin" "$BASHRC"; then
    sed -i "\|^${begin}\$|,\|^${end}\$|d" "$BASHRC"
    action='обновлён'
  else
    action='добавлен'
  fi

  trim_trailing_blank_lines
  printf '\n%s\n%s\n%s\n' "$begin" "$body" "$end" >>"$BASHRC"
  printf '  %s: блок %s\n' "$begin" "$action"
}

# Условия внутри блока важнее самого вызова:
#   $- == *i*   — только интерактивный шелл, иначе вопрос полезет в скрипты,
#                 в scp и в агентские сессии, и они повиснут на read;
#   -z $TMUX    — внутри tmux спрашивать нечего, иначе рекурсия при новом окне;
#   || true     — сломанный ws не должен ронять шелл. Терминал важнее хука.
install_ws_hook() {
  install_block "$WS_MARK_BEGIN" "$WS_MARK_END" \
    "if [[ \$- == *i* ]] && [[ -z \${TMUX:-} ]] && command -v ws >/dev/null 2>&1; then
  ws --ask || true
fi"
}

# Старые alias и функции находятся внутри проверенного managed-блока.
# Комментируем блок целиком вместе с маркерами: определения перестают
# действовать, строки сохраняются, а новый блок ставится независимо от старого.
comment_legacy_agent_block() {
  local range first last

  range="$(awk -v begin="$AGENTS_MARK_BEGIN" -v end="$AGENTS_MARK_END" '
    $0 == begin { first = NR; inside = 1 }
    inside && /^[[:space:]]*alias[[:space:]]+(codex-dev|claude-own)=/ {
      legacy = 1
    }
    inside && /^[[:space:]]*(codex|claude)[[:space:]]*\(\)[[:space:]]*\{/ {
      legacy = 1
    }
    inside && $0 == end {
      if (legacy) print first, NR
      exit
    }
  ' "$BASHRC")"
  [[ -n $range ]] || return 0
  read -r first last <<<"$range"

  sed -i -e "${first},${last}s|^|# |" "$BASHRC"
  printf '  закомментирован старый блок входов codex/claude: строки %s-%s\n' \
    "$first" "$last"
}

install_dev_agents_entry() {
  local quoted_bin

  if [[ ! -x $DEV_AGENTS_BIN/ccx ]]; then
    printf '  нет %s/ccx — PATH ставлю на будущий путь\n' "$DEV_AGENTS_BIN"
  fi

  printf -v quoted_bin '%q' "$DEV_AGENTS_BIN"
  install_block "$AGENTS_MARK_BEGIN" "$AGENTS_MARK_END" \
    "export PATH=$quoted_bin:\$PATH"
}

# Старые alias могли быть поставлены вручную вне управляемого блока. Целиком
# комментируем физическую строку: это безопасно и для составной команды, и для
# определения с продолжением через обратный слеш.
comment_legacy_alias() {
  local name="$1" line lines=''
  local -a sed_arguments=()
  local -i line_number=0 count=0

  while IFS= read -r line || [[ -n $line ]]; do
    (( line_number += 1 ))
    [[ $line =~ ^[[:space:]]*alias[[:space:]]+${name}= ]] || continue
    sed_arguments+=(-e "${line_number}s|^|# |")
    lines+="${lines:+, }$line_number"
    (( count += 1 ))
  done <"$BASHRC"

  if (( count )); then
    sed -i "${sed_arguments[@]}" "$BASHRC"
    printf '  закомментирован старый alias %s: строки %s\n' "$name" "$lines"
  fi
}

# До управляемого блока входы жили ручными симлинками в ~/bin. Удаляем только
# известные симлинки на те же launcher'ы; чужой файл с таким именем не трогаем.
remove_legacy_symlink() {
  local name="$1" launcher="$2" path path_target launcher_target
  path="$HOME/bin/$name"

  [[ -L $path && -e $path && -e $launcher ]] || return 0
  path_target="$(readlink -f -- "$path")" || return 0
  launcher_target="$(readlink -f -- "$launcher")" || return 0

  if [[ -n $path_target && -n $launcher_target && $path_target == "$launcher_target" ]]; then
    rm -- "$path"
    printf '  удалён старый симлинк %s\n' "$path"
  fi
}

report_legacy_remainders() {
  local remaining
  remaining="$(awk '
    /^[[:space:]]*#/ { next }
    /alias[[:space:]]+(codex-dev|claude-own)=/ { print NR ":" $0; next }
    /(^|[;[:space:]])(function[[:space:]]+)?(codex|claude)[[:space:]]*(\(\))?[[:space:]]*\{/ {
      print NR ":" $0
    }
  ' "$BASHRC")"

  if [[ -n $remaining ]]; then
    printf 'Остались необработанные legacy-строки:\n%s\n' "$remaining"
  fi
}

main() {
  if [[ ! -f $BASHRC ]]; then
    printf 'нет файла %s\n' "$BASHRC" >&2
    exit 1
  fi

  printf 'Правлю %s\n' "$BASHRC"
  validate_blocks
  if [[ ${WORKSTATION_MIGRATE_LEGACY_AGENTS:-} == 1 ]]; then
    comment_legacy_agent_block
    comment_legacy_alias codex-dev
    comment_legacy_alias claude-own
  fi
  install_ws_hook
  if [[ -n $DEV_AGENTS_BIN ]]; then install_dev_agents_entry; fi
  if [[ ${WORKSTATION_MIGRATE_LEGACY_AGENTS:-} == 1 ]]; then
    if [[ -n $DEV_AGENTS_BIN ]]; then remove_legacy_symlink codex-dev "$DEV_AGENTS_BIN/codex-developer.sh"; fi
    if [[ -n $DEV_AGENTS_BIN ]]; then remove_legacy_symlink claude-own "$DEV_AGENTS_BIN/claude-owner.sh"; fi
    report_legacy_remainders
  fi
  printf 'Готово. Убрать — удалить блок между его маркерами.\n'
}

main "$@"
