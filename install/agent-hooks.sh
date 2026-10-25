#!/usr/bin/env bash
# Вешает возврат раскладки в английскую на отправку сообщения агенту.
#
# Отдельным шагом, а не частью `make link`, по той же причине, что и
# shell-hook.sh: правит ~/.claude/settings.json и ~/.codex/hooks.json — файлы
# пользователя со своей историей, а не конфиги из репозитория.
#
# Событие одно и то же у обоих агентов — UserPromptSubmit, момент отправки
# промпта. Это ровно тот момент, когда руки уходят с русского текста обратно
# на команды.
#
# Идемпотентен: свой хук (узнаётся по имени команды) переписывается, чужие не
# трогаются.
set -euo pipefail

COMMAND="$HOME/.local/bin/xkb-agent-reset"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_HOOKS="$HOME/.codex/hooks.json"

require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf 'нужен python3 — им правится JSON агентов\n' >&2
    exit 1
  fi
}

require_helper() {
  if [[ ! -x $HOME/.local/bin/xkb-agent-reset ]]; then
    printf 'нет ~/.local/bin/xkb-agent-reset — сначала make link\n' >&2
    exit 1
  fi
}

# Оба агента держат хуки в одинаковой структуре
# {"hooks": {"UserPromptSubmit": [{"hooks": [{"type": "command", ...}]}]}},
# отличаются только файлом: у Claude Code это общий settings.json, у Codex —
# отдельный hooks.json. Поэтому правилка одна на двоих.
install_hook() {
  local file="$1" label="$2"

  mkdir -p "$(dirname "$file")"
  python3 - "$file" "$COMMAND" <<'PY'
import json, os, shlex, shutil, sys

path, command = sys.argv[1], sys.argv[2]

data = {}
if os.path.exists(path):
    shutil.copy2(path, path + ".bak")
    with open(path, encoding="utf-8") as handle:
        text = handle.read().strip()
    data = json.loads(text) if text else {}

hooks = data.setdefault("hooks", {})
event = hooks.setdefault("UserPromptSubmit", [])

def is_layout_hook(hook):
    command = hook.get("command") or ""
    return "xkb-group" in command or "xkb-agent-reset" in command


# Снимаем и текущую команду, и старый прямой вызов xkb-group: после обновления
# старый хук не должен продолжать переключать раскладку в чужом окне. Остальные
# команды сохраняем, даже если они лежат в том же элементе события.
kept = []
for entry in event:
    old_hooks = entry.get("hooks", [])
    new_hooks = [hook for hook in old_hooks if not is_layout_hook(hook)]
    if new_hooks == old_hooks:
        kept.append(entry)
    elif new_hooks:
        kept.append({**entry, "hooks": new_hooks})

kept.append({"hooks": [{"type": "command", "command": shlex.quote(command)}]})
hooks["UserPromptSubmit"] = kept

with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY
  printf '  %-12s %s\n' "$label" "$file"
}

main() {
  require_python
  require_helper

  printf 'Ставлю хуки возврата раскладки\n'
  install_hook "$CLAUDE_SETTINGS" "Claude Code"
  install_hook "$CODEX_HOOKS" "Codex"

  printf '\nCodex выполняет хук только после подтверждения: открой codex и\n'
  printf 'набери /hooks — там надо один раз согласиться (trust).\n'
  printf 'Claude Code подхватит хук при следующем запуске.\n'
}

main "$@"
