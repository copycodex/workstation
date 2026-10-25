#!/usr/bin/env bash
# Ставит системные пакеты. Требует sudo — это единственный шаг, который его
# требует, поэтому он вынесен отдельно от link.sh.
#
# Всё перечисленное есть в репозиториях Ubuntu 26.04 в актуальных версиях
# (проверено 2026-08-13): neovim 0.11.6, tmux 3.6a, lazygit 0.57, fd 10.3.
# Сторонних PPA сознательно нет — на новой машине не должно быть шагов
# «сначала добавь репозиторий».
set -euo pipefail

# Языковые серверы и форматтеры здесь не ставятся: их тянет mason внутри
# neovim при первом запуске. Держать два списка одного и того же — источник
# расхождений (канон, п.8).
PACKAGES=(
  neovim
  tmux
  lazygit
  ripgrep     # используется fuzzy-поиском в nvim
  fd-find     # быстрый обход дерева для того же поиска
  xclip       # копирование из tmux в системный буфер
  build-essential # нужен treesitter для сборки парсеров
  libx11-dev      # заголовки XKB, ими собирается xkb-group
  x11-utils       # xprop — по нему сторож узнаёт активное окно
  git
  curl
  unzip           # fonts.sh распаковывает им архив шрифта
  fontconfig      # fc-cache/fc-list, ими же fonts.sh проверяет установку
)

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    printf 'Этот скрипт рассчитан на Debian/Ubuntu (apt-get не найден).\n' >&2
    exit 1
  fi
}

install_packages() {
  printf 'Ставлю: %s\n' "${PACKAGES[*]}"
  sudo apt-get update -qq
  sudo apt-get install -y "${PACKAGES[@]}"
}

# В Debian/Ubuntu бинарник fd называется fdfind — имя fd занято другим пакетом.
# nvim ищет именно fd, поэтому кладём шим в ~/.local/bin.
link_fd_shim() {
  local bin_dir="$HOME/.local/bin"

  if command -v fd >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v fdfind >/dev/null 2>&1; then
    return 0
  fi

  mkdir -p "$bin_dir"
  ln -sf "$(command -v fdfind)" "$bin_dir/fd"
  printf 'Создан шим %s/fd -> fdfind\n' "$bin_dir"
}

main() {
  require_apt
  install_packages
  link_fd_shim
  printf 'Пакеты установлены.\n'
}

main "$@"
