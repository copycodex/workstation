#!/usr/bin/env bash
# Раскладывает конфиги из репозитория по ~/.config симлинками.
# Sudo не требуется. Идемпотентен: повторный запуск ничего не ломает.
#
# Симлинк, а не копия — чтобы правка в ~/.config/nvim и правка в репозитории
# были одним и тем же файлом, и `git status` сразу показывал изменения.
set -euo pipefail

# Корень репозитория берём от расположения самого скрипта, а не от cwd и не от
# «где-то рядом» (канон, п.4). Скрипт лежит в <repo>/install/, значит корень — на
# уровень выше. Путь резолвим до абсолютного, чтобы симлинки не оказались битыми.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_HOME="$HOME/.local/bin"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

log() {
  printf '  %s\n' "$*"
}

# Уводит существующий конфиг в бэкап. Уже правильный симлинк не трогаем —
# иначе каждый повторный запуск плодил бы пустые каталоги бэкапа.
backup_if_needed() {
  local target="$1" source="$2"

  if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
    return 1
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    log "старое сохранено в $BACKUP_DIR/$(basename "$target")"
  fi

  return 0
}

link_one() {
  local source="$1" target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'нет источника: %s\n' "$source" >&2
    return 1
  fi

  if ! backup_if_needed "$target" "$source"; then
    log "$(basename "$target") — уже связан, пропуск"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  log "$target -> $source"
}

# ~/.local/bin попадает в PATH из ~/.profile, и только если каталог существовал
# на момент логина. На чистой машине мы его сами и создаём — значит до
# перелогина ни `ws`, ни шим `fd` не найдутся, а хук в ~/.bashrc промолчит
# (у него `command -v ws`) и это выглядит как «хук не поставился».
warn_if_bin_not_in_path() {
  case ":$PATH:" in
    *":$BIN_HOME:"*) return 0 ;;
  esac

  log "$BIN_HOME не в PATH — команда ws заработает после перелогина"
}

main() {
  printf 'Раскладываю конфиги из %s\n' "$REPO_ROOT"
  link_one "$REPO_ROOT/nvim" "$CONFIG_HOME/nvim"
  link_one "$REPO_ROOT/tmux/tmux.conf" "$CONFIG_HOME/tmux/tmux.conf"
  link_one "$REPO_ROOT/git/config" "$CONFIG_HOME/git/config"
  link_one "$REPO_ROOT/git/mr.conf" "$CONFIG_HOME/git/mr.conf"
  link_one "$REPO_ROOT/git/mr.sh" "$CONFIG_HOME/git/mr.sh"
  link_one "$REPO_ROOT/bin/ws" "$BIN_HOME/ws"
  link_one "$REPO_ROOT/bin/xkb-agent-reset" "$BIN_HOME/xkb-agent-reset"
  warn_if_bin_not_in_path
  printf 'Готово.\n'
}

main "$@"
