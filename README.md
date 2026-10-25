# Workstation configuration

A personal workstation setup for Neovim, tmux, Git and a small session launcher. The repository contains scripts and symlinked configuration. Review the scripts before using them on your machine.

## Install

Clone the repository, then run `make bootstrap` to install packages, fonts and links. `make link` only creates user-level symlinks. `make check` runs the tests and reports local tool and symlink status. `make fonts`, `make xkb`, `make shell-hook`, and `make agent-hooks` are optional steps. `make cheat` opens the local HTML reference pages.

## Sessions

Edit `tmux/sessions.conf` for your own project directories, then run `ws`. Rows contain a session, window, directory and layout. The `@repo` form creates terminal and editor windows for a repository when its directory exists.

## Encrypted files in Neovim

Files named `*.sops.yml`, `*.sops.yaml`, `*.sops.json`, `*.sops.tfvars` or `*.sops.env` open as ciphertext. Run `:SopsEdit` to decrypt into the current buffer and `:SopsLock` to reload ciphertext. Save with `:w`; the plugin encrypts before writing. Set your own SOPS age key through standard SOPS environment variables. For project-specific keys, set `vim.g.sops_identity_routes` before loading `init.lua` to a list of `{ root = '/absolute/project', identity = '/absolute/key' }` entries.

Plaintext remains visible in the editor until locked. The configuration disables automatic clipboard sharing and, on lock or close, clears registers that contain whole plaintext lines; it cannot remove earlier clipboard-manager history.

Known limitation: partial yanks (charwise, visual block, appends to `A`–`Z`), recorded macros and the `:` register can keep plaintext fragments after lock. Avoid yanking from a decrypted buffer, or clear registers yourself before sharing the screen.

## Agent context

`AGENTS.md` is a template for repository instructions used by coding agents. Fill in the repository description, checks, commit rules, and state location before use. `CLAUDE.md` points to the same instructions. Start a local `HANDOFF.md` from `HANDOFF.md.example` to record the dated state and next action. `tasks/README.md` explains task briefs, with `tasks/task-000-example.md` as a starting point.
