.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help bootstrap packages fonts link xkb shell-hook agent-hooks cheat check

help: ## Показать доступные команды
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

bootstrap: packages fonts link xkb ## Полная установка на чистой машине (нужен sudo)
	@echo
	@echo "Осталось: запустить nvim — mason сам поставит серверы и форматтеры."
	@echo "Проверить состояние: make check"

packages: ## Поставить системные пакеты (нужен sudo)
	@./install/packages.sh

fonts: ## Поставить символы Nerd Fonts для иконок (sudo не нужен)
	@./install/fonts.sh

link: ## Разложить конфиги симлинками в ~/.config (sudo не нужен)
	@./install/link.sh

xkb: ## Собрать xkb-group и включить раскладку «на окно» (без sudo)
	@./install/xkb.sh

shell-hook: ## Блоки в ~/.bashrc: меню сессий ws и команда ccx
	@./install/shell-hook.sh

agent-hooks: ## Возвращать английскую раскладку при отправке сообщения агенту
	@./install/agent-hooks.sh

cheat: ## Открыть шпаргалки по tmux и nvim в браузере
	@xdg-open docs/tmux.html >/dev/null 2>&1 &
	@xdg-open docs/nvim.html >/dev/null 2>&1 &
	@echo "Шпаргалки: docs/tmux.html и docs/nvim.html"

check: ## Проверить, что всё на месте
	@./test/shell-hook.test.sh
	@./test/git-workspace.test.sh
	@./test/ws-repositories.test.sh
	@./test/nvim-sops.test.sh
	@echo "=== бинарники ==="
	@for b in nvim tmux lazygit rg fd git xkb-group xkb-agent-reset; do \
		printf '  %-9s ' "$$b"; command -v $$b || echo "— НЕТ"; \
	done
	@echo "=== симлинки ==="
	@for p in "$$HOME/.config/nvim" "$$HOME/.config/tmux/tmux.conf" "$$HOME/.local/bin/ws"; do \
		printf '  %-28s ' "$$(basename $$p)"; \
		if [ -L "$$p" ]; then readlink "$$p"; else echo "— НЕ СИМЛИНК"; fi; \
	done
	@echo "=== шрифты ==="
	@printf '  %-28s ' "Symbols Nerd Font"; \
		if fc-list 2>/dev/null | grep -i 'symbols nerd font' >/dev/null; then \
			echo "есть"; else echo "— НЕТ, иконки будут квадратами (make fonts)"; fi
	@echo "=== версии ==="
	@nvim --version 2>/dev/null | head -1 || true
	@tmux -V 2>/dev/null || true
