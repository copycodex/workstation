#!/usr/bin/env bash
# Собирает xkb-group в ~/.local/bin и переводит панель XFCE на раскладку
# «своя для каждого окна». Sudo не требуется.
#
# Два действия в одном скрипте потому, что решают одну задачу: чтобы в
# терминале была английская раскладка независимо от того, что писали в
# браузере или в Telegram. Первое даёт возможность вернуть раскладку
# программно, второе — не тащить русский из чужого окна.
#
# Идемпотентен: пересборка и повторная установка свойства ничего не ломают.
set -euo pipefail

# Корень репозитория — от расположения скрипта, а не от cwd (канон, п.4).
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

BIN_HOME="$HOME/.local/bin"
SOURCE="$REPO_ROOT/install/xkb-group.c"
TARGET="$BIN_HOME/xkb-group"

log() {
  printf '  %s\n' "$*"
}

build_helper() {
  if ! command -v gcc >/dev/null 2>&1; then
    printf 'нет gcc — сначала make packages\n' >&2
    return 1
  fi

  if [[ ! -f /usr/include/X11/XKBlib.h ]]; then
    printf 'нет заголовков libx11-dev — сначала make packages\n' >&2
    return 1
  fi

  mkdir -p "$BIN_HOME"
  gcc -O2 -o "$TARGET" "$SOURCE" -lX11
  log "$TARGET собран"
}

# Номер плагина на панели у каждой машины свой, поэтому ищем его по типу, а не
# зашиваем (канон, п.4). Строки вывода вида «/plugins/plugin-11   xkb».
find_xkb_plugin() {
  xfconf-query -c xfce4-panel -l -v 2>/dev/null \
    | awk '$2 == "xkb" { print $1; exit }'
}

# 0 — одна раскладка на весь сеанс, 1 — на приложение, 2 — на окно.
# Берём 2: окон терминала бывает несколько, и каждое должно помнить своё.
set_per_window_layout() {
  local plugin property

  if ! command -v xfconf-query >/dev/null 2>&1; then
    log "xfconf-query не найден — раскладка «на окно» пропущена (не XFCE?)"
    return 0
  fi

  plugin="$(find_xkb_plugin)"
  if [[ -z $plugin ]]; then
    log "плагина раскладки нет на панели — добавь его и запусти ещё раз"
    return 0
  fi

  property="$plugin/group-policy"
  xfconf-query -c xfce4-panel -p "$property" -n -t int -s 2 >/dev/null 2>&1 \
    || xfconf-query -c xfce4-panel -p "$property" -s 2 >/dev/null
  log "$property = 2 (раскладка на окно)"

  # Плагин перечитывает политику только при старте.
  if [[ -n ${DISPLAY:-} ]] && command -v xfce4-panel >/dev/null 2>&1; then
    xfce4-panel --restart >/dev/null 2>&1 || true
    log "панель перезапущена"
  fi
}

main() {
  printf 'Настраиваю раскладку\n'
  build_helper
  set_per_window_layout
  printf 'Готово.\n'
}

main "$@"
