#!/usr/bin/env bash
# Ставит символьный набор Nerd Fonts в ~/.local/share/fonts.
#
# Нужен для иконок в neo-tree и статусной строке: без него терминал рисует
# пустые квадраты вместо глифов папок и файлов.
#
# Берётся именно SymbolsOnly (~3 МБ), а не полноценный шрифт (~100 МБ):
# fontconfig подставляет из него недостающие глифы к любому текущему шрифту
# терминала, поэтому менять шрифт не требуется.
#
# Sudo не нужен — установка пользовательская. Идемпотентен.
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
URL='https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.zip'
SHA256='8e617904b980fe3648a4b116808788fe50c99d2d495376cb7c0badbd8a564c47'

log() {
  printf '  %s\n' "$*"
}

# grep без -q намеренно: с -q он закрывает пайп, fc-list ловит SIGPIPE, и при
# `set -o pipefail` проверка всегда возвращала бы «не установлено».
is_installed() {
  fc-list 2>/dev/null | grep -i 'symbols nerd font' >/dev/null
}

require_tools() {
  local tool
  for tool in curl unzip fc-cache sha256sum; do
    command -v "$tool" >/dev/null || {
      printf 'нет %s — поставь его и повтори\n' "$tool" >&2
      exit 1
    }
  done
}

cleanup_font_tmp() {
  if [[ -n ${font_tmp:-} ]]; then rm -rf -- "$font_tmp"; fi
}

install_font() {
  font_tmp="$(mktemp -d)"
  trap cleanup_font_tmp EXIT

  log 'качаю NerdFontsSymbolsOnly'
  curl -fsSL -o "$font_tmp/nf.zip" "$URL"

  printf '%s  %s\n' "$SHA256" "$font_tmp/nf.zip" | sha256sum --check --status || {
    printf 'font archive SHA-256 mismatch\n' >&2
    return 1
  }

  mkdir -p "$FONT_DIR"
  unzip -qo "$font_tmp/nf.zip" -d "$FONT_DIR"

  log 'обновляю кеш шрифтов'
  fc-cache -f "$FONT_DIR" >/dev/null
}

main() {
  if is_installed; then
    log 'Symbols Nerd Font уже стоит, пропуск'
    return 0
  fi

  require_tools
  install_font
  log "готово: $FONT_DIR"
  log 'терминал нужно перезапустить, чтобы он подхватил шрифт'
}

main "$@"
