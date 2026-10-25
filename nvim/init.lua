--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Глифы даёт символьный набор Nerd Fonts, его ставит `make fonts`. Он работает
-- подстановкой к текущему шрифту терминала, поэтому менять шрифт не нужно.
vim.g.have_nerd_font = true

-- [[ Setting options ]]
--  See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  if not vim.b.sops_plain then vim.o.clipboard = 'unnamedplus' end
end)

-- Команды работают и на русской раскладке: langmap подменяет буквы ЙЦУКЕН на
-- латиницу в нормальном и визуальном режиме. Без него на русской раскладке
-- нажатое «о» вместо перехода вниз вставляет пустую строку, и переключаться
-- на английский приходится ради каждой команды.
--
-- Порядок символов в двух половинах строго соответствует друг другу: слева
-- русские буквы, справа латинские на тех же физических клавишах.
--
-- Одних букв мало. На клавишах со знаками в ЙЦУКЕН сидят ж э б ю х ъ ё, и без
-- них на русской раскладке нет `:` (командная строка), `.` (повтор), `"`
-- (регистры), `,`/`;` (повтор поиска по строке), `[`/`]` и `` ` ``. Вторая
-- строка добавляет их парами; `;` и `,` внутри langmap экранируются.
--
-- Чего langmap НЕ покрывает:
--   * сочетания с Ctrl (`<C-o>`, `<C-w>`) — Neovim разбирает их до подстановки;
--   * `$` и `^` — в ЙЦУКЕН этих символов нет вообще, Shift-4 даёт `;`,
--     Shift-6 даёт `:`, и обе замены уже заняты своими командами;
--   * командную строку и режим вставки — langmap на них не действует
--     по определению, поэтому ниже стоит автовозврат раскладки.
vim.o.langmap = table.concat({
  'ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  'фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz',
  [==[ж\;Ж:э'Э"б\,Б<ю.Ю>х[Х{ъ]Ъ}ё`Ё~№#]==],
}, ',')

-- Enable break indent
vim.o.breakindent = true

-- Enable undo/redo changes even after closing and reopening a file
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Give multi-key mappings such as <Space>sg enough time to be entered comfortably.
vim.o.timeoutlen = 1000

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic Config & Keymaps
-- See `:help vim.diagnostic.Opts`
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- `?*`, а не `*`: глоб `*` матчит пустую строку, поэтому под `*.sops.yaml`
-- попадал сам `.sops.yaml` — конфиг creation_rules, в котором секретов нет.
-- Открытие его гасило shada на всю сессию и предлагало `:SopsEdit` над
-- незашифрованным файлом. Требуем хотя бы один символ до суффикса.
local sops_patterns = { '?*.sops.yml', '?*.sops.yaml', '?*.sops.json', '?*.sops.tfvars', '?*.sops.env' }

-- Защиты — постусловие любого перехода в plaintext, а не свойство
-- способа, которым буфер был открыт. Имя `*.sops.*` может появиться позже
-- через `:file`, API или будущую команду, поэтому единственная функция зовётся
-- самим `:SopsEdit` перед заменой содержимого. Автокоманды зовут её тоже —
-- заранее, чтобы уже зашифрованный буфер был готов к явному редактированию.
-- shada буфер-локальной не бывает: её нужно отключить на всю сессию,
-- иначе yank секрета уедет в shada.
local function enable_sops_trace_guards(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.swapfile = false
    vim.opt_local.undofile = false
    vim.opt_local.backup = false
    vim.opt_local.writebackup = false
    vim.opt_local.modeline = false
  end)
  vim.opt.shada = ''
end

vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  desc = 'No on-disk traces when editing sops-encrypted files',
  group = vim.api.nvim_create_augroup('sops-no-traces', { clear = true }),
  pattern = sops_patterns,
  callback = function(args)
    enable_sops_trace_guards(args.buf)
    vim.notify('sops: следы на диске отключены; буфер остаётся зашифрованным', vim.log.levels.INFO)
  end,
})

-- Явное редактирование sops-файла в буфере; plaintext идёт только через stdin/stdout.
local function is_sops_path(path)
  local name = vim.fs.basename(path)
  for _, pattern in ipairs(sops_patterns) do
    if vim.fn.match(name, '\\C' .. vim.fn.glob2regpat(pattern)) >= 0 then return true end
  end
  return false
end

local function current_sops_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' or not is_sops_path(path) then
    vim.notify('sops: current buffer is not a supported sops file', vim.log.levels.ERROR)
    return nil
  end
  return vim.fn.fnamemodify(path, ':p')
end

-- `fs_realpath` отвечает только про существующий файл, а identity нужна и для
-- нового. Лексический запасной путь тут не годится: он оставляет симлинки
-- неразрешёнными, и текстовый префикс перестаёт быть доказательством места —
-- каталог-симлинк наружу увёл бы чужой файл под ключ проекта, а симлинк
-- внутрь оставил бы файл проекта без него. Поэтому резолвится ближайший
-- существующий предок, а недостающий хвост приписывается к нему. Уровень
-- считается отсутствующим, только если и realpath, и lstat вернули ENOENT:
-- realpath даёт ENOENT также для существующего висячего симлинка.
local function resolve_real_location(path)
  -- Keep `..` until existing symlinks are resolved: escape/.. is not the
  -- lexical parent of escape. Normalize only the tail attached to realpath.
  local current = path
  local tail = {}
  while true do
    local resolved, realpath_error = vim.uv.fs_realpath(current)
    if resolved then return vim.fs.normalize(vim.fs.joinpath(resolved, table.concat(tail, '/')), { expand_env = false }) end
    if not realpath_error or not realpath_error:match '^ENOENT:' then return nil end

    local entry, lstat_error = vim.uv.fs_lstat(current)
    if entry or not lstat_error or not lstat_error:match '^ENOENT:' then return nil end

    local parent = vim.fs.dirname(current)
    if parent == current then return nil end
    table.insert(tail, 1, vim.fs.basename(current))
    current = parent
  end
end

-- Optional local routing: set vim.g.sops_identity_routes before this config loads.
-- Each entry is { root = '/absolute/project', identity = '/absolute/age/key' }.
local function configured_sops_identity(path)
  local real_path = resolve_real_location(path)
  if not real_path then return nil end
  for _, route in ipairs(vim.g.sops_identity_routes or {}) do
    local real_root = route.root and vim.uv.fs_realpath(route.root)
    if real_root and type(route.identity) == 'string' and (real_path == real_root or vim.startswith(real_path, real_root .. '/')) then return route.identity end
  end
  return nil
end

local function sops_process_env(path)
  local identity = configured_sops_identity(path)
  if not identity then return nil end

  local environment = vim.fn.environ()
  environment.SOPS_AGE_KEY_FILE = identity
  environment.SOPS_AGE_KEY = nil
  return environment
end

-- uv.spawn expects a complete `KEY=value` vector when an environment is
-- supplied.
local function sops_uv_env(path)
  local inherited = sops_process_env(path)
  if not inherited then return nil end

  local environment = {}
  for name, value in pairs(inherited) do
    table.insert(environment, name .. '=' .. tostring(value))
  end
  table.sort(environment)
  return environment
end

local function buffer_text()
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  return vim.bo.endofline and text .. '\n' or text
end

local function replace_buffer(text)
  local endofline = text:sub(-1) == '\n'
  if endofline then text = text:sub(1, -2) end
  local lines = text == '' and { '' } or vim.split(text, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.endofline = endofline
end

local function clear_buffer_undo()
  local undolevels = vim.bo.undolevels
  vim.bo.undolevels = -1
  local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)
  vim.api.nvim_buf_set_lines(0, 0, 1, false, first_line)
  vim.bo.undolevels = undolevels
end

local function set_sops_filetype(path)
  local filetypes = { yml = 'yaml', yaml = 'yaml', json = 'json', tfvars = 'terraform', env = 'sh' }
  vim.bo.filetype = filetypes[path:match '%.sops%.([^.]*)$']
end

-- For plaintext buffers: пока буфер помечен plaintext, языковые
-- серверы к нему не прицеплены. Бриф требует и filetype, и отсутствие каналов
-- наружу, а `set_sops_filetype` поднимал над расшифрованным буфером yamlls и
-- отправлял ему весь секрет первым же `didOpen`. Подсветку даёт treesitter в
-- этом же процессе, поэтому filetype остаётся, а LSP уходит.
--
-- Держится это не перечнем серверов — он разъехался бы с таблицей `servers` на
-- первом новом языке, — а `buftype`: `vim.lsp.enable` выходит из своего
-- FileType-колбэка на первой же проверке `buftype ~= ''`, то есть **до**
-- attach и до `didOpen`. Отцеплять уже прицепленное поздно: `LspAttach`
-- приходит после того, как документ отправлен.
local function detach_language_servers(buf)
  -- `_uninitialized = true` обязателен: по умолчанию `get_clients` не
  -- показывает клиентов, которые ещё поднимаются, а такой клиент уже прицеплен
  -- к буферу и отправит `didOpen` сразу после initialize — то есть уже поверх
  -- расшифрованного текста.
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf, _uninitialized = true }) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end

local function attach_language_servers(buf) pcall(vim.api.nvim_exec_autocmds, 'FileType', { group = 'nvim.lsp.enable', buffer = buf }) end

local function file_stamp(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then return false end
  return table.concat({ stat.dev, stat.ino, stat.size, stat.mtime.sec, stat.mtime.nsec }, ':')
end

-- Один гейт на границе «содержимое буфера → внешний процесс». Пока в буфере
-- plaintext, единственный разрешённый sink — внутренний путь sops encrypt;
-- filetype и имена нынешних/будущих форматтеров здесь намеренно неизвестны.
local sops_encrypt_sink = {}
local function guard_buffer_external_process(buf, sink)
  if not vim.b[buf].sops_plain or sink == sops_encrypt_sink then return end
  local message = 'sops: plaintext may only be sent to sops encrypt; external process blocked'
  vim.notify(message, vim.log.levels.ERROR)
  error(message, 0)
end

-- Флаг `sops_plain` и маркер `SOPS:PLAIN` обязаны следовать за содержимым
-- буфера, а не жить рядом с ним. Перечислять способы подменить содержимое
-- бесполезно: их больше, чем кажется (`autoread` по `:checktime`, `:edit!`,
-- любая будущая команда перечитывания). Правило одно — буфер, прочитанный с
-- диска, несёт то, что лежит на диске, то есть шифротекст, и расшифрованным
-- состоянием он быть перестаёт.
--
-- Снять флаг мало: Neovim переносит undo через перезагрузку (`undoreload`), и
-- один `u` вернул бы plaintext в буфер, у которого флага уже нет, — то есть в
-- обычный буфер, который `:w` пишет на диск как есть. Поэтому выход из
-- расшифрованного состояния снимает и флаг, и его undo одним действием;
-- `undoreload` для этого не годится, она глобальная и стоила бы undo после
-- перезагрузки всему Neovim, как `shada`.
local sops_plaintext_lines = {}
local sops_collecting = {}
local sops_watched_buffers = {}
local function sops_bufnr(buf) return buf == 0 and vim.api.nvim_get_current_buf() or buf end
local function update_sops_clipboard() vim.o.clipboard = vim.b.sops_plain and '' or 'unnamedplus' end

local function remember_sops_lines(buf, first, last)
  buf = sops_bufnr(buf)
  local remembered = sops_plaintext_lines[buf]
  if not remembered then return end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, first, last, false)) do
    line = vim.trim(line)
    if line ~= '' then remembered[line] = true end
  end
end

local function watch_sops_lines(buf)
  buf = sops_bufnr(buf)
  sops_plaintext_lines[buf] = {}
  sops_collecting[buf] = true
  remember_sops_lines(buf, 0, -1)
  if sops_watched_buffers[buf] then return end
  sops_watched_buffers[buf] = true
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, changed_buf, _, first, _, new_last)
      if sops_collecting[changed_buf] then remember_sops_lines(changed_buf, first, new_last) end
    end,
    on_detach = function(_, detached_buf) sops_watched_buffers[detached_buf] = nil end,
  })
end

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('sops-clipboard', { clear = true }),
  callback = update_sops_clipboard,
})
vim.api.nvim_create_autocmd('TextYankPost', {
  group = 'sops-clipboard',
  callback = function(args)
    if vim.b[args.buf].sops_plain then vim.o.clipboard = '' end
  end,
})

local function clear_sops_registers(buf)
  buf = sops_bufnr(buf)
  local plaintext = sops_plaintext_lines[buf] or {}
  local registers = { '"', '-', '+', '*', '.', '/' }
  for number = 0, 9 do
    registers[#registers + 1] = tostring(number)
  end
  for code = string.byte 'a', string.byte 'z' do
    registers[#registers + 1] = string.char(code)
  end
  -- Uppercase names address the same registers as lowercase names; writing
  -- to an uppercase name would append instead of clearing it.
  for _, name in ipairs(registers) do
    local ok, contents = pcall(vim.fn.getreg, name, 1, true)
    if ok then
      local contains_plaintext = false
      for _, value in ipairs(contents) do
        for line in tostring(value):gmatch '[^\n]+' do
          if plaintext[vim.trim(line)] then
            contains_plaintext = true
            break
          end
        end
        if contains_plaintext then break end
      end
      if contains_plaintext then
        if name == '.' then
          -- The last-inserted register is read-only to setreg. An empty insert
          -- in a disposable buffer replaces it without changing user text.
          local scratch = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_call(scratch, function() vim.cmd('normal! i' .. string.char(27)) end)
          vim.api.nvim_buf_delete(scratch, { force = true })
        else
          vim.fn.setreg(name, '')
        end
      end
    end
  end
  sops_plaintext_lines[buf] = nil
  sops_collecting[buf] = nil
end

local drop_plaintext_state
vim.api.nvim_create_autocmd({ 'BufUnload', 'BufDelete', 'BufWipeout' }, {
  group = 'sops-clipboard',
  callback = function(args)
    if vim.b[args.buf].sops_plain then drop_plaintext_state(args.buf) end
  end,
})

drop_plaintext_state = function(buf)
  buf = sops_bufnr(buf)
  if not vim.b[buf].sops_plain then return end
  if sops_collecting[buf] then remember_sops_lines(buf, 0, -1) end
  clear_sops_registers(buf)
  vim.b[buf].sops_plain = nil
  vim.b[buf].sops_cipher_stamp = nil
  vim.b[buf].sops_path = nil
  vim.api.nvim_buf_call(buf, clear_buffer_undo)
  vim.bo[buf].buftype = ''
  attach_language_servers(buf)
  update_sops_clipboard()
  vim.cmd.redrawstatus()
end

local function run_sops_decrypt(path)
  local environment = sops_process_env(path)
  local ok, process = pcall(vim.system, { 'sops', 'decrypt', path }, {
    cwd = vim.fs.dirname(path),
    env = environment,
    clear_env = environment ~= nil,
    text = true,
  })
  if not ok then return { code = -1, stderr = tostring(process) } end
  return process:wait()
end

local function run_sops_encrypt(buf, path, input)
  guard_buffer_external_process(buf, sops_encrypt_sink)
  -- `vim.system(..., { stdin = text })` подключает socketpair. sops 3.9.1
  -- открывает `/dev/stdin` заново и получает ENXIO на таком дескрипторе, поэтому
  -- stdin должен быть настоящим pipe(2), а не shell-трамплином через `cat`.
  local input_pipe, pipe_error = vim.uv.pipe { nonblock = true }
  if not input_pipe then return { code = -1, stderr = 'pipe: ' .. tostring(pipe_error) } end

  local stdin = vim.uv.new_pipe(false)
  local stdout = vim.uv.new_pipe(false)
  local stderr = vim.uv.new_pipe(false)
  local open_ok, open_error = pcall(stdin.open, stdin, input_pipe.write)
  if not open_ok then
    pcall(vim.uv.fs_close, input_pipe.read)
    pcall(vim.uv.fs_close, input_pipe.write)
    stdin:close()
    stdout:close()
    stderr:close()
    return { code = -1, stderr = 'pipe open: ' .. tostring(open_error) }
  end

  local stdout_chunks = {}
  local stderr_chunks = {}
  local stdout_done = false
  local stderr_done = false
  local stdin_done = false
  local process_done = false
  local exit_code = -1
  local exit_signal = 0
  local stream_error
  local process
  local spawn_error

  process, spawn_error = vim.uv.spawn('sops', {
    args = { 'encrypt', '--filename-override', path, '/dev/stdin' },
    cwd = vim.fs.dirname(path),
    env = sops_uv_env(path),
    stdio = { input_pipe.read, stdout, stderr },
  }, function(code, signal)
    exit_code = code
    exit_signal = signal
    process_done = true
    process:close()
  end)

  -- spawn дублирует read-end для ребёнка; родитель закрывает свою копию сразу,
  -- иначе sops не увидит EOF после закрытия write-end.
  pcall(vim.uv.fs_close, input_pipe.read)

  if not process then
    stdin:close()
    stdout:close()
    stderr:close()
    return { code = -1, stderr = tostring(spawn_error) }
  end

  local function read_stream(stream, chunks, mark_done)
    stream:read_start(function(err, data)
      if err and not stream_error then stream_error = err end
      if data then
        table.insert(chunks, data)
        return
      end
      stream:read_stop()
      stream:close()
      mark_done()
    end)
  end

  read_stream(stdout, stdout_chunks, function() stdout_done = true end)
  read_stream(stderr, stderr_chunks, function() stderr_done = true end)

  local function finish_stdin(err)
    if err and not stream_error then stream_error = err end
    stdin_done = true
    stdin:close()
  end

  if input == '' then
    finish_stdin()
  else
    stdin:write(input, function(err) finish_stdin(err) end)
  end

  local completed = vim.wait(30000, function() return process_done and stdin_done and stdout_done and stderr_done end, 10)
  if not completed then
    pcall(process.kill, process, 'sigterm')
    return { code = -1, stderr = 'sops process timed out' }
  end

  local collected_stderr = table.concat(stderr_chunks)
  if stream_error then
    exit_code = -1
    collected_stderr = collected_stderr .. '\npipe: ' .. tostring(stream_error)
  end
  return {
    code = exit_code,
    signal = exit_signal,
    stdout = table.concat(stdout_chunks),
    stderr = collected_stderr,
  }
end

local function has_sops_mac(path, output)
  local suffix = path:match '%.sops%.([^.]*)$'
  if suffix == 'yml' or suffix == 'yaml' then
    local metadata = output:match '^sops:[ \t]*\n(.*)$' or output:match '\nsops:[ \t]*\n(.*)$'
    if not metadata then return false end
    local mac = metadata:match '^([ \t]+mac:[^\n]*)' or metadata:match '\n([ \t]+mac:[^\n]*)'
    return mac ~= nil and mac:match 'mac:[ \t]*ENC%[[^\r\n]+%]' ~= nil
  end

  if suffix == 'env' then
    local mac = output:match '^sops_mac=(ENC%[[^\r\n]+%])' or output:match '\nsops_mac=(ENC%[[^\r\n]+%])'
    return mac ~= nil
  end

  if suffix == 'json' or suffix == 'tfvars' then
    local ok, document = pcall(vim.json.decode, output)
    return ok
      and type(document) == 'table'
      and type(document.sops) == 'table'
      and type(document.sops.mac) == 'string'
      and document.sops.mac:match '^ENC%[[^\r\n]+%]$' ~= nil
  end

  return false
end

-- Не перечисляем формы отказа. Замена разрешена только при положительном
-- доказательстве всего контракта: ребёнок завершился сам, вернул ноль и stdout
-- содержит цельный SOPS-документ с зашифрованным mac.
local function encrypt_failure(path, result)
  local completed = (result.signal == nil or result.signal == 0) and result.code == 0 and has_sops_mac(path, result.stdout or '')
  if completed then return nil end
  if vim.trim(result.stderr or '') ~= '' then return result end
  return {
    code = result.code,
    signal = result.signal,
    stderr = 'sops did not finish with a complete sops document',
  }
end

local function notify_sops_error(action, result) vim.notify(('sops %s failed; ciphertext was not replaced'):format(action), vim.log.levels.ERROR) end

local function sops_edit(opts)
  local path = current_sops_path()
  if not path then return end
  if vim.b.sops_plain then
    vim.notify('sops: buffer is already decrypted', vim.log.levels.INFO)
    return
  end
  if vim.bo.modified and not opts.bang then
    vim.notify('sops: unsaved changes; use :SopsEdit! to discard them', vim.log.levels.WARN)
    return
  end
  enable_sops_trace_guards(0)

  local input = buffer_text()
  local is_new_file = vim.fn.filereadable(path) == 0 and input == '\n'
  local decrypted
  if not is_new_file then
    local result = run_sops_decrypt(path)
    if result.code ~= 0 then
      notify_sops_error('decrypt', result)
      return
    end
    decrypted = result.stdout
  end

  detach_language_servers(0)
  vim.bo.buftype = 'acwrite'
  if decrypted then
    replace_buffer(decrypted)
    clear_buffer_undo()
  end

  vim.b.sops_plain = true
  watch_sops_lines(0)
  update_sops_clipboard()
  vim.b.sops_cipher_stamp = file_stamp(path)
  vim.b.sops_path = path
  set_sops_filetype(path)
  vim.bo.modified = false
  vim.cmd.redrawstatus()
end

local function sops_lock(opts)
  local path = current_sops_path()
  if not path then return end
  if not vim.b.sops_plain then
    vim.notify('sops: buffer is already encrypted', vim.log.levels.INFO)
    return
  end
  if vim.bo.modified and not opts.bang then
    vim.notify('sops: unsaved changes; use :SopsLock! to discard them', vim.log.levels.WARN)
    return
  end

  remember_sops_lines(0, 0, -1)
  sops_collecting[vim.api.nvim_get_current_buf()] = false
  local ok, err = pcall(vim.cmd, 'silent noautocmd edit!')
  if not ok then
    sops_collecting[vim.api.nvim_get_current_buf()] = true
    vim.notify('sops: could not reload ciphertext', vim.log.levels.ERROR)
    return
  end
  drop_plaintext_state(0)
  vim.bo.modified = false
end

-- Шифротекст пишется через дескриптор уникального файла, который `mkstemp`
-- создаёт эксклюзивно в каталоге цели, и только этот файл переименовывается
-- поверх цели. Предсказуемый pathname с обычным `writefile` позволил бы
-- подсунуть симлинк, а два писателя делили бы один inode. Цель резолвится через
-- `fs_realpath`, иначе rename заменил бы симлинк файлом.
local function write_text(path, text)
  local target = vim.uv.fs_realpath(path) or path
  local descriptor, temporary = vim.uv.fs_mkstemp(target .. '.sops-nvim-XXXXXX')
  if not descriptor then return false, 'fs_mkstemp: ' .. tostring(temporary) end

  local function fail(message)
    if descriptor then
      pcall(vim.uv.fs_close, descriptor)
      descriptor = nil
    end
    pcall(vim.uv.fs_unlink, temporary)
    return false, message
  end

  local stat = vim.uv.fs_stat(target)
  local permissions = stat and bit.band(stat.mode, tonumber('7777', 8)) or tonumber('600', 8)
  local chmod_ok, chmod_error = vim.uv.fs_fchmod(descriptor, permissions)
  if not chmod_ok then return fail('fs_fchmod: ' .. tostring(chmod_error)) end

  local offset = 0
  while offset < #text do
    local written, write_error = vim.uv.fs_write(descriptor, text:sub(offset + 1), offset)
    if not written then return fail('fs_write: ' .. tostring(write_error)) end
    if written == 0 then return fail 'fs_write: wrote zero bytes' end
    offset = offset + written
  end

  local sync_ok, sync_error = vim.uv.fs_fsync(descriptor)
  if not sync_ok then return fail('fs_fsync: ' .. tostring(sync_error)) end
  local close_ok, close_error = vim.uv.fs_close(descriptor)
  if not close_ok then return fail('fs_close: ' .. tostring(close_error)) end
  descriptor = nil

  local rename_ok, rename_error = vim.uv.fs_rename(temporary, target)
  if not rename_ok then return fail('fs_rename: ' .. tostring(rename_error)) end
  return true
end

local function finish_sops_write()
  vim.bo.modified = false
  vim.api.nvim_exec_autocmds('BufWritePost', { buffer = 0, modeline = false })
end

local function write_sops_buffer()
  if not vim.b.sops_plain then
    local command = vim.v.cmdbang == 1 and 'silent noautocmd write!' or 'silent noautocmd write'
    local ok = pcall(vim.cmd, command)
    if not ok or vim.bo.modified then
      vim.bo.modified = true
      error('sops: write aborted', 0)
    end
    finish_sops_write()
    return
  end

  local path = current_sops_path()
  if not path then
    -- Ветка недостижима по построению: `BufWriteCmd` висит на тех же
    -- `sops_patterns`, из которых `is_sops_path` собирает свою проверку.
    -- Оставлена ради контракта — выход из `BufWriteCmd` без ошибки означает
    -- «записал», и молчаливый `return` соврал бы Vim ровно так же, как это
    -- делал отказ записи до фикса A2.
    vim.bo.modified = true
    error('sops: write aborted', 0)
  end
  if vim.v.cmdbang == 0 and vim.b.sops_cipher_stamp ~= file_stamp(path) then
    vim.bo.modified = true
    vim.notify('sops: file changed on disk; use :write! to overwrite it', vim.log.levels.ERROR)
    error('sops: write aborted', 0)
  end
  local result = run_sops_encrypt(0, path, buffer_text())
  local failure = encrypt_failure(path, result)
  if failure then
    vim.bo.modified = true
    notify_sops_error('encrypt', failure)
    error('sops: write aborted', 0)
  end

  local ok, err = write_text(path, result.stdout)
  if not ok then
    vim.bo.modified = true
    vim.notify('sops: could not write ciphertext:\n' .. err, vim.log.levels.ERROR)
    error('sops: write aborted', 0)
  end
  vim.b.sops_cipher_stamp = file_stamp(path)
  clear_sops_registers(0)
  watch_sops_lines(0)
  finish_sops_write()
end

local function reject_unsafe_sops_write(args)
  if not vim.b[args.buf].sops_plain then return end
  if args.event == 'BufWritePre' and is_sops_path(args.match) then return end
  local message = 'sops: partial, alternate, append, and pipe writes are disabled while plaintext is loaded'
  vim.notify(message, vim.log.levels.ERROR)
  error(message, 0)
end

local sops_edit_group = vim.api.nvim_create_augroup('sops-buffer-edit', { clear = true })
vim.api.nvim_create_autocmd('BufWriteCmd', {
  desc = 'Encrypt decrypted sops buffers before writing',
  group = sops_edit_group,
  pattern = sops_patterns,
  callback = write_sops_buffer,
})
-- Источник имени — переименование буфера, поэтому и слежение, и отказ висят на
-- нём, а не на следующей за ним записи. Легальный `:saveas` в другой sops-файл
-- переносит `sops_path` на новое имя; уход расшифрованного буфера за пределы
-- `sops_patterns` отвергается с возвратом прежнего имени — иначе буфер с
-- открытым текстом остаётся под именем, которого команды не узнают.
vim.api.nvim_create_autocmd('BufFilePost', {
  desc = 'Keep a decrypted buffer inside the sops files',
  group = sops_edit_group,
  pattern = '*',
  callback = function(args)
    if not vim.b[args.buf].sops_plain then return end
    local name = vim.api.nvim_buf_get_name(args.buf)
    if is_sops_path(name) then
      vim.b[args.buf].sops_path = vim.fn.fnamemodify(name, ':p')
      return
    end
    local previous = vim.b[args.buf].sops_path
    if previous then vim.api.nvim_buf_set_name(args.buf, previous) end
    local message = 'sops: renaming a decrypted buffer outside sops files is disabled'
    vim.notify(message, vim.log.levels.ERROR)
    error(message, 0)
  end,
})
-- Подстраховка на случай клиента, который поднимается асинхронно и приходит
-- уже после расшифровки: `buftype` останавливает решение о запуске до attach,
-- а этот обработчик — то, что всё же прицепилось. Он именно подстраховка, а не
-- основной гейт: `LspAttach` приходит после `didOpen`, то есть документ к
-- этому моменту уже отправлен.
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'No language server on a decrypted sops buffer',
  group = sops_edit_group,
  callback = function(args)
    if not vim.b[args.buf].sops_plain then return end
    -- Отцеплять приходится следующим тиком: внутри `LspAttach` Neovim ещё не
    -- закончил attach и помечает буфер прицепленным уже после обработчика.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) or not vim.b[args.buf].sops_plain then return end
      pcall(vim.lsp.buf_detach_client, args.buf, args.data.client_id)
    end)
  end,
})
vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Ciphertext read from disk cannot stay marked as plaintext',
  group = sops_edit_group,
  pattern = '*',
  callback = function(args) drop_plaintext_state(args.buf) end,
})
vim.api.nvim_create_autocmd({ 'BufWritePre', 'FileWritePre', 'FileAppendPre', 'FilterWritePre' }, {
  desc = 'Reject writes that bypass sops encryption',
  group = sops_edit_group,
  pattern = '*',
  callback = reject_unsafe_sops_write,
})

vim.api.nvim_create_user_command('SopsEdit', sops_edit, { bang = true })
vim.api.nvim_create_user_command('SopsLock', sops_lock, { bang = true })
local mason_pins = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/mason-pins.lua')

-- Раскладка сама возвращается в английскую при выходе из режима вставки.
--
-- langmap чинит нормальный режим, но на командную строку и на вставку он не
-- действует вовсе: `:w`, имя файла в `:e`, аргументы `:s` — всё это латиница
-- мимо него. Отсюда и брались постоянные переключения руками.
--
-- Поэтому раскладку двигаем сами: выход из вставки и вход в `:` ставят
-- английскую, вход во вставку возвращает ту, в которой писали до этого.
--
-- Поиск (`/`) намеренно не трогаем: по русскому тексту ищут по-русски.
--
-- Без DISPLAY блок не заводится: по ssh и в консоли переключать нечего, там
-- работает только langmap. Утилиту ставит `make xkb` — см. install/xkb.sh.
local xkb_group = vim.fn.exepath 'xkb-group'

if xkb_group ~= '' and vim.env.DISPLAY then
  -- Ничего не запомнено, пока из вставки не вышли хотя бы раз. Ноль здесь был
  -- бы не «нейтральным значением», а командой: первый же вход во вставку гасил
  -- бы русскую раскладку, выбранную руками до него.
  local insert_group = nil

  local function lock_group(group) vim.system { xkb_group, tostring(group) } end

  -- Английская ставится в колбэке чтения, а не рядом с ним: это два отдельных
  -- процесса, порядок их выполнения не гарантирован, и без цепочки чтение
  -- могло бы вернуть уже переключённую группу вместо запомненной.
  local function remember_group_and_switch_to_english()
    vim.system({ xkb_group }, { text = true }, function(result)
      insert_group = tonumber((result.stdout or ''):match '%d+') or 0
      vim.schedule(function() lock_group(0) end)
    end)
  end

  local layout = vim.api.nvim_create_augroup('workstation-keyboard-layout', { clear = true })

  vim.api.nvim_create_autocmd('InsertLeave', {
    desc = 'Запомнить раскладку вставки и вернуть английскую',
    group = layout,
    callback = remember_group_and_switch_to_english,
  })

  vim.api.nvim_create_autocmd('InsertEnter', {
    desc = 'Вернуть раскладку, в которой писали в прошлый раз',
    group = layout,
    callback = function()
      if insert_group then lock_group(insert_group) end
    end,
  })

  vim.api.nvim_create_autocmd('CmdlineEnter', {
    desc = 'Команды набираются латиницей',
    group = layout,
    pattern = ':',
    callback = function() lock_group(0) end,
  })
end

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
local lazy_commit = '306a05526ada86a7b30af95c5cc81ffba93fef97'
local lazy_head = vim.fn.system { 'git', '-C', lazypath, 'rev-parse', 'HEAD' }
if vim.v.shell_error ~= 0 or vim.trim(lazy_head) ~= lazy_commit then
  local out = vim.fn.system { 'git', '-C', lazypath, 'fetch', '--depth=1', 'origin', lazy_commit }
  if vim.v.shell_error ~= 0 then error('Unable to fetch pinned lazy.nvim commit: ' .. out) end
  out = vim.fn.system { 'git', '-C', lazypath, 'checkout', '--detach', lazy_commit }
  if vim.v.shell_error ~= 0 then error('Unable to check out pinned lazy.nvim commit: ' .. out) end
end
local verified_head = vim.fn.system { 'git', '-C', lazypath, 'rev-parse', 'HEAD' }
if vim.v.shell_error ~= 0 or vim.trim(verified_head) ~= lazy_commit then error 'lazy.nvim commit verification failed' end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added via a link or github org/name. To run setup automatically, use `opts = {}`
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Alternatively, use `config = function() ... end` for full control over the configuration.
  -- If you prefer to call `setup` explicitly, use:
  --    {
  --        'lewis6991/gitsigns.nvim',
  --        config = function()
  --            require('gitsigns').setup({
  --                -- Your gitsigns configuration here
  --            })
  --        end,
  --    }
  --
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`.
  --
  -- See `:help gitsigns` to understand what each configuration keys does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  {
    'lewis6991/gitsigns.nvim',
    ---@module 'gitsigns'
    ---@type Gitsigns.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      signs = {
        add = { text = '+' }, ---@diagnostic disable-line: missing-fields
        change = { text = '~' }, ---@diagnostic disable-line: missing-fields
        delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
        topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
        changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `opts` key (recommended), the configuration runs
  -- after the plugin has been loaded as `require(MODULE).setup(opts)`.
  --
  -- Useful plugin to show you pending keybinds.
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    ---@module 'which-key'
    ---@type wk.Opts
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      -- Delay between pressing a key and opening which-key (milliseconds)
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },

      -- Document existing key chains
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin
  --
  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    -- By default, Telescope is included and acts as your picker for everything.

    -- If you would like to switch to a different picker (like snacks, or fzf-lua)
    -- you can disable the Telescope plugin by setting enabled to false and enable
    -- your replacement picker by requiring it explicitly (e.g. 'custom.plugins.snacks')

    -- Note: If you customize your config for yourself,
    -- it’s best to remove the Telescope plugin config entirely
    -- instead of just disabling it here, to keep your config clean.
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- If encountering errors, see telescope-fzf-native README for installation instructions
      {
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
      -- If you later switch picker plugins, this is where to update these mappings.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf

          -- Find references for the word under your cursor.
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

          -- Jump to the implementation of the word under your cursor.
          -- Useful when your language has ways of declaring types without an actual implementation.
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

          -- Jump to the definition of the word under your cursor.
          -- This is where a variable was first declared, or where a function is defined, etc.
          -- To jump back, press <C-t>.
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

          -- Fuzzy find all the symbols in your current document.
          -- Symbols are things like variables, functions, types, etc.
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

          -- Fuzzy find all the symbols in your current workspace.
          -- Similar to document symbols, except searches over your entire project.
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

          -- Jump to the type of the word under your cursor.
          -- Useful when you're not sure what type a variable is and you want to see
          -- the definition of its *type*, not where it was *defined*.
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      -- Override default behavior and theme when searching
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set(
        'n',
        '<leader>s/',
        function()
          builtin.live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        { desc = '[S]earch [/] in Open Files' }
      )

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP Plugins
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      {
        'mason-org/mason.nvim',
        enabled = vim.env.WORKSTATION_TEST ~= '1',
        ---@module 'mason.settings'
        ---@type MasonSettings
        ---@diagnostic disable-next-line: missing-fields
        opts = {},
      },
      -- Maps LSP server names between nvim-lspconfig and Mason package names.
      { 'mason-org/mason-lspconfig.nvim', enabled = vim.env.WORKSTATION_TEST ~= '1' },
      { 'WhoIsSethDaniel/mason-tool-installer.nvim', enabled = vim.env.WORKSTATION_TEST ~= '1' },

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Иерархия вызовов — то, что в JetBrains делает Call Hierarchy:
          -- `grc` показывает, кто вызывает функцию под курсором, `grC` — кого
          -- вызывает она. Результат уходит в quickfix, ходить по нему `]q`/`[q`.
          map('grc', vim.lsp.buf.incoming_calls, 'Call hierarchy: кто вызывает')
          map('grC', vim.lsp.buf.outgoing_calls, 'Call hierarchy: кого вызывает')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following code creates a keymap to toggle inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --  See `:help lsp-config` for information about keys and how to configure
      ---@type table<string, vim.lsp.Config>
      -- Language servers for common project files.
      local servers = {
        ts_ls = {},
        gopls = {},

        -- Свой `on_attach` перекрывает тот, что идёт в конфиге nvim-lspconfig:
        -- апстримный зовёт `vim.lsp.codelens.enable`, которого в Neovim 0.11
        -- нет (есть только `refresh`), и каждый открытый `.tf` даёт
        -- ON_ATTACH_ERROR. Тот же класс, что пин treesitter, — снимать вместе
        -- с ним, когда 0.12 приедет в штатные репозитории.
        terraformls = {
          on_attach = function(_, bufnr) vim.lsp.codelens.refresh { bufnr = bufnr } end,
        },

        bashls = {},
        jsonls = {},

        -- ansiblels выключен: он намертво вешает редактор, Плейбуки обслуживает yamlls как обычный YAML.
        yamlls = {
          filetypes = { 'yaml' },
        },

        -- Special Lua Config, as recommended by neovim help docs
        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
                --  See https://github.com/neovim/nvim-lspconfig/issues/3189
                library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
                  '${3rd}/luv/library',
                  '${3rd}/busted/library',
                }),
              },
            })
          end,
          ---@type lspconfig.settings.lua_ls
          settings = {
            Lua = {
              format = { enable = false }, -- Disable formatting (formatting is done by stylua)
            },
          },
        },
      }

      -- Ensure the servers and tools above are installed
      --
      -- To check the current status of installed tools and/or manually install
      -- other tools, you can run
      --    :Mason
      --
      -- You can press `g?` for help in this menu.
      local ensure_installed = mason_pins

      if vim.env.WORKSTATION_TEST ~= '1' then require('mason-tool-installer').setup { ensure_installed = ensure_installed } end

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  -- Autoformat
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          guard_buffer_external_process(0)
          require('conform').format { async = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    ---@module 'conform'
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Автоформат только там, где формат канонический и правка не создаёт
        -- шумный диф в существующих репозиториях. YAML сознательно не входит:
        -- в в некоторых проектах есть свой .yamllint, prettier с ним конфликтует.
        -- Для остального — `<leader>f` вручную.
        local enabled_filetypes = {
          lua = true,
          go = true,
          terraform = true,
        }
        if enabled_filetypes[vim.bo[bufnr].filetype] then
          return { timeout_ms = 500 }
        else
          return nil
        end
      end,
      default_format_opts = {
        lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
      },
      -- You can also specify external formatters in here.
      formatters_by_ft = {
        lua = { 'stylua' },
        go = { 'gofumpt' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        terraform = { 'terraform_fmt' },
        hcl = { 'terraform_fmt' },
        javascript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        markdown = { 'prettier' },
      },
    },
  },

  -- Autocompletion
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      -- Snippet Engine
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
        opts = {},
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        -- 'default' (recommended) for mappings similar to built-in completions
        --   <c-y> to accept ([y]es) the completion.
        --    This will auto-import if your LSP supports it.
        --    This will expand snippets if the LSP sent a snippet.
        -- 'super-tab' for tab to accept
        -- 'enter' for enter to accept
        -- 'none' for no mappings
        --
        -- For an understanding of why the 'default' preset is recommended,
        -- you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        --
        -- All presets have the following mappings:
        -- <tab>/<s-tab>: move to right/left of your snippet expansion
        -- <c-space>: Open menu or open docs if already open
        -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
        -- <c-e>: Hide menu
        -- <c-k>: Toggle signature help
        --
        -- See `:help blink-cmp-config-keymap` for defining your own keymap
        preset = 'default',

        -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
        --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
      },

      appearance = {
        -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'snippets' },
      },

      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See `:help blink-cmp-config-fuzzy` for more information
      fuzzy = { implementation = 'lua' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  {
    -- JetBrains Darcula-inspired colorscheme.
    'xiantang/darcula-dark.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      vim.opt.termguicolors = true
      vim.cmd.colorscheme 'darcula-dark'
    end,
  },

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@module 'todo-comments'
    ---@type TodoOptions
    ---@diagnostic disable-next-line: missing-fields
    opts = { signs = false },
  },

  -- Collection of various small independent plugins/modules
  {
    'nvim-mini/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup {
        -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
        mappings = {
          around_next = 'aa',
          inside_next = 'ii',
        },
        n_lines = 500,
      }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'

      local function inactive_statusline()
        local window = tonumber(vim.g.statusline_winid) or 0
        local buffer = vim.api.nvim_win_get_buf(window)
        local marker = vim.b[buffer].sops_plain and '%#MiniStatuslineModeReplace# SOPS:PLAIN ' or ''
        return '%#MiniStatuslineInactive#%F%=' .. marker
      end

      -- Set `use_icons` to true if you have a Nerd Font
      statusline.setup {
        use_icons = vim.g.have_nerd_font,
        content = { inactive = inactive_statusline },
      }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end

      local default_fileinfo = statusline.section_fileinfo
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_fileinfo = function(args)
        return statusline.combine_groups {
          { hl = 'MiniStatuslineModeReplace', strings = { vim.b.sops_plain and 'SOPS:PLAIN' or '' } },
          { hl = 'MiniStatuslineFileinfo', strings = { default_fileinfo(args) } },
        }
      end

      -- ... and there is more!
      --  Check out: https://github.com/nvim-mini/mini.nvim
    end,
  },

  -- Used to highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'master',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
    config = function()
      require('nvim-treesitter.configs').setup {
        -- Базовые парсеры плюс языки типичных проектов (см. таблицу `servers` выше)
        ensure_installed = {
          'bash',
          'c',
          'diff',
          'html',
          'lua',
          'luadoc',
          'markdown',
          'markdown_inline',
          'query',
          'vim',
          'vimdoc',
          -- jsonc здесь нет намеренно: парсера с таким именем в nvim-treesitter
          -- не существует, json покрывает и его.
          'go',
          'gomod',
          'gosum',
          'typescript',
          'tsx',
          'javascript',
          'json',
          'yaml',
          'terraform',
          'hcl',
          'dockerfile',
          'sql',
          'toml',
        },
        highlight = { enable = true },
        indent = { enable = true },
      }
    end,
  },

  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommended keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- { import = 'custom.plugins' },
  --
  -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
  -- Or use telescope!
  -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
  -- you can continue same window with `<space>sr` which resumes last telescope search
}, { ---@diagnostic disable-line: missing-fields
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
