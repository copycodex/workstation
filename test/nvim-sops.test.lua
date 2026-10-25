local root = assert(vim.env.SOPS_TEST_ROOT)
local project = root .. '/project'
local encrypted = project .. '/secrets.sops.yml'
local uppercase = project .. '/secrets.SOPS.YML'
local readonly = project .. '/readonly.sops.yml'
local external = project .. '/external.sops.yml'
local missing_sops = project .. '/missing.sops.yml'
local broken = project .. '/broken.sops.yml'
local reload = project .. '/reload.sops.yml'
local sops_config = project .. '/.sops.yaml'
local undo_reload = project .. '/undo.sops.yml'
local lsp_probe = project .. '/lsp.sops.yml'
local lsp_late = project .. '/late.sops.yml'
local atomic = project .. '/atomic.sops.yml'
local register_write = project .. '/register-write.sops.yml'
local symlink_atomic = project .. '/symlink-atomic.sops.yml'
local symlink_victim = project .. '/symlink-victim.txt'
local pipe_transport = project .. '/pipe-transport.sops.yml'
local signalled = project .. '/signalled.sops.yml'
local nonsops = project .. '/nonsops.sops.yml'
local valid_json = project .. '/valid.sops.json'
local valid_tfvars = project .. '/valid.sops.tfvars'
local valid_env = project .. '/valid.sops.env'
local format_fixtures = {
  { label = 'yaml', path = project .. '/format.sops.yml', filetype = 'yaml' },
  { label = 'json', path = project .. '/format.sops.json', filetype = 'json' },
  { label = 'tfvars', path = project .. '/format.sops.tfvars', filetype = 'terraform' },
  { label = 'env', path = project .. '/format.sops.env', filetype = 'sh' },
}
local ordinary_format = project .. '/format.json'
local renamed = project .. '/renamed.sops.yml'
local ordinary = project .. '/ordinary.yml'
local no_rule = project .. '/new.sops.env'
local alternate = root .. '/plaintext.yml'
local appended = root .. '/appended.yml'
local safe_copy = project .. '/copy.sops.yml'
local unsafe_saveas = root .. '/saveas.yml'
local log = assert(vim.env.SOPS_TEST_LOG)
local identity_home = root .. '/home'
local exampleorg_root = assert(vim.env.SOPS_TEST_EXAMPLEORG_ROOT)
vim.g.sops_identity_routes = { { root = exampleorg_root, identity = identity_home .. '/.config/exampleorg-demo-service/age/identity.txt' } }
local exampleorg_route = exampleorg_root .. '/route.sops.yml'
local other_route = assert(vim.env.SOPS_TEST_OTHER_ROOT) .. '/route.sops.yml'
local outside_root = assert(vim.env.SOPS_TEST_OUTSIDE_ROOT)

local function evidence(key, value)
  if vim.env.SOPS_TEST_EVIDENCE == '1' then
    local rendered = tostring(value):gsub('\n', '\\n')
    print(('%s=%s'):format(key, rendered))
  end
end

local function read(path)
  local file = assert(io.open(path, 'rb'))
  local content = file:read '*a'
  file:close()
  return content
end

local function write(path, content)
  local file = assert(io.open(path, 'wb'))
  assert(file:write(content))
  file:close()
end

local function line_count(path)
  local count = 0
  for _ in io.lines(path) do
    count = count + 1
  end
  return count
end

local function edit(path) vim.cmd('edit ' .. vim.fn.fnameescape(path)) end

-- Инвариант двусторонний, и это не педантизм: односторонняя проверка «есть
-- флаг ⇒ в буфере нет шифротекста» пропустила B7 — plaintext, вернувшийся
-- через undo в буфер с уже снятым флагом. Проверяются обе стороны, а поверх
-- них дисковый инвариант, который от флага не зависит вовсе и поэтому ловит
-- шов этого класса даже тогда, когда сторону угадали не ту.
local plaintext_sentinels = { 'clear%-value', 'changed%-value', 'unsaved%-value' }

local function buffer_has_ciphertext()
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find 'ENC%[AES256_GCM' then return true end
  end
  return false
end

local function buffer_has_plaintext()
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    for _, sentinel in ipairs(plaintext_sentinels) do
      if line:find(sentinel) then return true end
    end
  end
  return false
end

local function marker_shown() return MiniStatusline.section_fileinfo({ trunc_width = 120 }):find('SOPS:PLAIN', 1, true) ~= nil end

local function sops_files_with_plaintext()
  local found = {}
  for _, dir in ipairs { project, root } do
    for name, kind in vim.fs.dir(dir) do
      if kind == 'file' and name:lower():find '%.sops%.' then
        local content = read(dir .. '/' .. name)
        for _, sentinel in ipairs(plaintext_sentinels) do
          if content:find(sentinel) then table.insert(found, name) end
        end
      end
    end
  end
  return found
end

local function assert_no_plaintext_on_disk(label)
  local found = sops_files_with_plaintext()
  assert(#found == 0, label .. ': plaintext on disk in ' .. table.concat(found, ', '))
end

local function assert_plaintext_invariant(label)
  assert(marker_shown() == (vim.b.sops_plain == true), label .. ': marker disagrees with flag')
  assert(not (vim.b.sops_plain and buffer_has_ciphertext()), label .. ': ciphertext under the flag')
  assert(not (not vim.b.sops_plain and buffer_has_plaintext()), label .. ': plaintext without the flag')
  assert_no_plaintext_on_disk(label)
end

-- Deleting an ordinary buffer must preserve macros and yanks.
vim.cmd.enew()
vim.fn.setreg('a', 'ordinary-macro')
vim.api.nvim_buf_delete(0, { force = true })
assert(vim.fn.getreg 'a' == 'ordinary-macro', 'ordinary buffer deletion erased register a')

-- Cleanup follows the text through numbered-register shifts, including shifts
-- caused by a later delete in an ordinary buffer.
edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SECRET_ONE', 'SECRET_TWO', 'tail' })
vim.cmd 'normal! ggdd'
vim.cmd 'normal! dd'
assert(vim.fn.getreg '2' == 'SECRET_ONE\n')
vim.cmd 'SopsLock!'
assert(vim.fn.getreg '2' == '', 'first deleted plaintext survived numbered-register shift')

edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SECRET_THREE', 'tail' })
local shifted_plain_buffer = vim.api.nvim_get_current_buf()
vim.cmd 'normal! ggdd'
vim.cmd('hide edit ' .. vim.fn.fnameescape(ordinary))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'ordinary deletion', 'tail' })
vim.cmd 'normal! ggdd'
assert(vim.fn.getreg '2' == 'SECRET_THREE\n')
vim.cmd 'edit!'
vim.api.nvim_buf_delete(shifted_plain_buffer, { force = true })
assert(vim.fn.getreg '2' == '', 'plaintext survived ordinary delete and buffer close')

edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SECRET_NAMED', 'tail' })
vim.cmd 'normal! gg"ayy'
vim.cmd('hide edit ' .. vim.fn.fnameescape(ordinary))
vim.cmd 'normal! ggdd'
vim.cmd 'edit!'
edit(encrypted)
vim.cmd 'SopsLock!'
assert(vim.fn.getreg 'a' == '', 'named plaintext survived ordinary operations and lock')

edit(encrypted)
vim.cmd.SopsEdit()
vim.fn.setreg('a', 'ordinary macro')
vim.cmd 'SopsLock!'
assert(vim.fn.getreg 'a' == 'ordinary macro', 'lock erased ordinary macro')
edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_delete(0, { force = true })
assert(vim.fn.getreg 'a' == 'ordinary macro', 'close erased ordinary macro')

edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'SECRET_CLIPBOARD', 'tail' })
vim.cmd 'normal! gg"+yy'
vim.cmd 'normal! "*yy'
vim.cmd 'SopsLock!'
assert(vim.fn.getreg '+' == '' and vim.fn.getreg '*' == '', 'plaintext survived clipboard cleanup')

edit(encrypted)
vim.cmd.SopsEdit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { '' })
vim.cmd('normal! gg0iSECRET_INSERT' .. string.char(27))
vim.fn.setreg('/', 'SECRET_INSERT')
assert(vim.fn.getreg '.' == 'SECRET_INSERT')
vim.cmd 'SopsLock!'
assert(vim.fn.getreg '.' == '' and vim.fn.getreg '/' == '', 'insert or search register survived lock: ' .. vim.inspect { vim.fn.getreg '.', vim.fn.getreg '/' })

edit(register_write)
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'secret: changed-value'
vim.cmd 'normal! "ayy'
vim.cmd.write()
assert(vim.b.sops_plain and vim.fn.getreg 'a' == '', 'encrypted write retained plaintext register')
vim.cmd 'SopsLock!'

-- A plaintext yank is removed on lock, but a later ordinary overwrite wins.
edit(encrypted)
vim.cmd.SopsEdit()
vim.cmd 'normal! "ayy'
assert(vim.fn.getreg('a'):find('clear-value', 1, true))
vim.cmd 'SopsLock!'
assert(vim.fn.getreg 'a' == '', 'plaintext register survived lock')
edit(encrypted)
vim.cmd.SopsEdit()
vim.cmd 'normal! "ayy'
vim.fn.setreg('a', 'new ordinary macro')
vim.cmd 'SopsLock!'
assert(vim.fn.getreg 'a' == 'new ordinary macro', 'lock erased later register content')
edit(encrypted)
vim.cmd.SopsEdit()
vim.cmd 'normal! "+yy'
vim.cmd 'normal! "*yy'
assert(vim.fn.getreg('+'):find('clear-value', 1, true))
assert(vim.fn.getreg('*'):find('clear-value', 1, true))
vim.api.nvim_buf_delete(0, { force = true })
assert(vim.fn.getreg '+' == '' and vim.fn.getreg '*' == '', 'plaintext clipboard survived buffer close')
edit(encrypted)
vim.cmd.SopsEdit()
vim.cmd 'normal! "ayy'
local first_plain_buffer = vim.api.nvim_get_current_buf()
vim.cmd('hide edit ' .. vim.fn.fnameescape(reload))
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'second-plaintext-buffer'
vim.cmd 'normal! "ayy'
vim.api.nvim_buf_delete(first_plain_buffer, { force = true })
assert(vim.fn.getreg('a'):find('second-plaintext-buffer', 1, true), 'closing first buffer erased second buffer yank')
vim.api.nvim_buf_delete(0, { force = true })
assert(vim.fn.getreg 'a' == '', 'second plaintext buffer yank survived close')

edit(uppercase)
local calls_before_uppercase_edit = line_count(log)
local uppercase_edit_ok = pcall(vim.cmd.SopsEdit)
assert(not uppercase_edit_ok)
assert(not vim.b.sops_plain)
assert(line_count(log) == calls_before_uppercase_edit)
evidence('A1_uppercase_edit_ok', uppercase_edit_ok)
evidence('A1_sops_plain', vim.b.sops_plain)
evidence('A1_sops_calls', line_count(log) - calls_before_uppercase_edit)

-- C3: имя sops-файла может появиться после событий открытия. Защиты обязаны
-- быть постусловием самого перехода в plaintext, независимо от того, получил
-- ли буфер имя через `:file` на новом/открытом буфере или через API.
local function assert_sops_edit_enables_trace_guards(label, name_buffer)
  name_buffer()
  vim.bo.swapfile = true
  vim.bo.undofile = true
  vim.opt_local.backup = true
  vim.opt_local.writebackup = true
  vim.bo.modeline = true
  vim.o.shada = "'10"

  vim.cmd.SopsEdit()
  assert(vim.b.sops_plain, label .. ': buffer did not enter plaintext state')
  assert(not vim.bo.swapfile, label .. ': swapfile remained enabled')
  assert(not vim.bo.undofile, label .. ': undofile remained enabled')
  assert(not vim.opt_local.backup:get(), label .. ': backup remained enabled')
  assert(not vim.opt_local.writebackup:get(), label .. ': writebackup remained enabled')
  assert(not vim.bo.modeline, label .. ': modeline remained enabled')
  assert(vim.o.shada == '', label .. ': shada remained enabled')
  evidence('C3_' .. label .. '_guards', 'swap=false undo=false backup=false writebackup=false modeline=false shada=empty')
  vim.cmd 'bwipeout!'
end

assert_sops_edit_enables_trace_guards('enew_file', function()
  vim.cmd.enew()
  vim.cmd('file ' .. vim.fn.fnameescape(project .. '/new.sops.yml'))
end)

assert_sops_edit_enables_trace_guards('open_buffer_file', function()
  edit(ordinary)
  vim.cmd('file ' .. vim.fn.fnameescape(renamed))
end)

assert_sops_edit_enables_trace_guards('api_name', function()
  vim.cmd.enew()
  vim.api.nvim_buf_set_name(0, project .. '/api.sops.yml')
end)

edit(readonly)
local readonly_before = read(readonly)
local write_post_count = 0
vim.api.nvim_create_autocmd('BufWritePost', {
  buffer = 0,
  callback = function() write_post_count = write_post_count + 1 end,
})
vim.bo.readonly = true
vim.api.nvim_set_current_line 'ciphertext: changed'
local readonly_write_ok = pcall(vim.cmd.write)
assert(read(readonly) == readonly_before)
assert(vim.bo.modified)
assert(write_post_count == 0)
evidence('A2_write_ok', readonly_write_ok)
evidence('A2_errmsg', vim.v.errmsg)
evidence('A2_disk_unchanged', read(readonly) == readonly_before)
evidence('A2_modified', vim.bo.modified)
evidence('A2_write_post_count', write_post_count)
vim.cmd 'write!'
assert(read(readonly) == 'ciphertext: changed\n')
assert(not vim.bo.modified)
assert(write_post_count == 1)
evidence('A2_force_disk_updated', read(readonly) == 'ciphertext: changed\n')
evidence('A2_force_modified', vim.bo.modified)
evidence('A2_force_write_post_count', write_post_count)
assert_no_plaintext_on_disk 'A2'

edit(external)
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'secret: changed-value'
write(external, 'external ciphertext\n')
local external_write_ok = pcall(vim.cmd.write)
assert(not external_write_ok)
assert(read(external) == 'external ciphertext\n')
assert(vim.bo.modified)
evidence('A4_write_ok', external_write_ok)
evidence('A4_external_change_preserved', read(external) == 'external ciphertext\n')
evidence('A4_modified', vim.bo.modified)
vim.cmd 'SopsLock!'
assert_no_plaintext_on_disk 'A4'

edit(missing_sops)
local saved_path = vim.env.PATH
local saved_notify = vim.notify
local notifications = {}
vim.env.PATH = root .. '/empty-bin'
vim.notify = function(message) table.insert(notifications, message) end
local missing_sops_ok = pcall(vim.cmd.SopsEdit)
assert(missing_sops_ok)
vim.notify = saved_notify
vim.env.PATH = saved_path
assert(not vim.b.sops_plain)
assert(vim.api.nvim_get_current_line():find 'ENC%[AES256_GCM')
assert(table.concat(notifications, '\n'):find('sops decrypt failed', 1, true))
assert(not table.concat(notifications, '\n'):find('ENOENT', 1, true))
evidence('A6_command_ok', missing_sops_ok)
evidence('A6_sops_plain', vim.b.sops_plain)
evidence('A6_notification', table.concat(notifications, ' | '))
assert_no_plaintext_on_disk 'A6'

edit(encrypted)
vim.cmd.SopsEdit()
assert(vim.o.clipboard == '', 'plaintext must disable clipboard export')
vim.cmd 'normal! "ayyl'
assert(vim.fn.getreg('a'):find('clear-value', 1, true))
vim.cmd.SopsLock()
assert(vim.fn.getreg 'a' == '', 'named plaintext register survived lock')
assert(vim.fn.getreg '0' == '', 'numbered plaintext register survived lock')
assert(vim.o.clipboard == 'unnamedplus')
evidence('clipboard_registers_cleared', true)

edit(encrypted)
assert(vim.api.nvim_get_current_line():find 'ENC%[AES256_GCM')
assert(not vim.b.sops_plain)

vim.api.nvim_buf_set_lines(0, -1, -1, false, { 'unsaved: keep-me' })
local unsaved_ciphertext = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local calls_before_refused_edit = line_count(log)
vim.cmd.SopsEdit()
assert(not vim.b.sops_plain)
assert(vim.bo.modified)
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), unsaved_ciphertext))
assert(line_count(log) == calls_before_refused_edit)
evidence('A5_sops_plain', vim.b.sops_plain)
evidence('A5_modified', vim.bo.modified)
evidence('A5_buffer_preserved', vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), unsaved_ciphertext))
evidence('A5_sops_calls', line_count(log) - calls_before_refused_edit)
vim.cmd 'SopsEdit!'
assert(vim.api.nvim_get_current_line() == 'secret: clear-value')
assert(vim.b.sops_plain)
evidence('A5_force_sops_plain', vim.b.sops_plain)
evidence('A5_force_discarded_unsaved_line', vim.api.nvim_buf_line_count(0) == 2)
assert(vim.bo.filetype == 'yaml')
assert(MiniStatusline.section_fileinfo({ trunc_width = 120 }):find 'SOPS:PLAIN')
local plain_window = vim.api.nvim_get_current_win()
vim.cmd.vnew()
vim.g.statusline_winid = plain_window
local inactive_marker = MiniStatusline.inactive():find('SOPS:PLAIN', 1, true) ~= nil
assert(inactive_marker)
evidence('A7_inactive_marker', inactive_marker)
vim.g.statusline_winid = nil
vim.cmd.close()
local decrypted_line = vim.api.nvim_get_current_line()
for _ = 1, 5 do
  vim.cmd.undo()
  assert(vim.api.nvim_get_current_line() == decrypted_line)
  assert(vim.b.sops_plain)
end
evidence('A3_line_after_five_undos', vim.api.nvim_get_current_line())
evidence('A3_sops_plain', vim.b.sops_plain)

vim.api.nvim_set_current_line 'secret: changed-value'
local before_failed_write = read(encrypted)
vim.env.SOPS_TEST_FAIL_ENCRYPT = '1'
local nonzero_write_ok = pcall(vim.cmd.write)
assert(not nonzero_write_ok)
assert(read(encrypted) == before_failed_write)
assert(vim.bo.modified)

local nonzero_wq_ok = pcall(vim.cmd, 'wq')
assert(not nonzero_wq_ok)
assert(read(encrypted) == before_failed_write)
assert(vim.api.nvim_buf_is_valid(0))
assert(vim.bo.modified)
evidence('C2_nonzero_write_ok', nonzero_write_ok)
evidence('C2_nonzero_wq_ok', nonzero_wq_ok)
evidence('C2_nonzero_ciphertext_unchanged', read(encrypted) == before_failed_write)
evidence('C2_nonzero_modified', vim.bo.modified)

vim.env.SOPS_TEST_FAIL_ENCRYPT = nil

-- B5: sops, вышедший нулём и молча, не считается успехом. Пустой stdout дошёл бы
-- до записи и обнулил файл секрета, а буфер отрапортовал бы, что сохранён.
local empty_notifications = {}
local notify_before_empty_encrypt = vim.notify
vim.notify = function(message) table.insert(empty_notifications, message) end
vim.env.SOPS_TEST_EMPTY_ENCRYPT = '1'
local empty_encrypt_ok = pcall(vim.cmd.write)
vim.env.SOPS_TEST_EMPTY_ENCRYPT = nil
vim.notify = notify_before_empty_encrypt
assert(not empty_encrypt_ok)
assert(read(encrypted) == before_failed_write)
assert(vim.fn.getfsize(encrypted) > 0)
assert(vim.bo.modified)
assert(table.concat(empty_notifications, '\n'):find('sops encrypt failed', 1, true))
evidence('B5_write_ok', empty_encrypt_ok)
evidence('B5_filesize', vim.fn.getfsize(encrypted))
evidence('B5_ciphertext_unchanged', read(encrypted) == before_failed_write)
evidence('B5_modified', vim.bo.modified)
evidence('B5_notification', table.concat(empty_notifications, ' | '))
assert_no_plaintext_on_disk 'B5'

-- B3: `uv.spawn` возвращает ошибку запуска отдельно от exit code. Encrypt
-- обязан превратить её в тот же безопасный отказ, что decrypt в A6.
local spawn_notifications = {}
local notify_before_spawn = vim.notify
local path_before_spawn = vim.env.PATH
vim.env.PATH = root .. '/empty-bin'
vim.notify = function(message) table.insert(spawn_notifications, message) end
local spawn_write_ok = pcall(vim.cmd.write)
vim.env.PATH = path_before_spawn
vim.notify = notify_before_spawn
assert(not spawn_write_ok)
assert(read(encrypted) == before_failed_write)
assert(vim.bo.modified)
assert(table.concat(spawn_notifications, '\n'):find('sops encrypt failed', 1, true))
assert(not table.concat(spawn_notifications, '\n'):find('ENOENT', 1, true))
evidence('B3_write_ok', spawn_write_ok)
evidence('B3_ciphertext_unchanged', read(encrypted) == before_failed_write)
evidence('B3_modified', vim.bo.modified)
evidence('B3_notification', table.concat(spawn_notifications, ' | '))
assert_no_plaintext_on_disk 'B3'

vim.cmd.write()
assert(read(encrypted):find 'ENC%[AES256_GCM,data:CCCC%]')
assert(vim.api.nvim_get_current_line() == 'secret: changed-value')
assert(vim.b.sops_plain)
assert(not vim.bo.modified)

local saved_ciphertext = read(encrypted)
assert(not pcall(vim.cmd, '1write!'))
assert(read(encrypted) == saved_ciphertext)
assert(not pcall(vim.cmd, 'write! ' .. vim.fn.fnameescape(alternate)))
assert(vim.fn.filereadable(alternate) == 0)

-- B2: предохранитель обещает отказ четырём формам записи, а покрыты были две.
-- Append кладёт plaintext во второй файл, filter — во временный файл фильтра;
-- обе отказывают, и это закрепляется здесь.
local buffer_before_filter = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local append_write_ok = pcall(vim.cmd, 'write >> ' .. vim.fn.fnameescape(appended))
local filter_ok = pcall(vim.cmd, '%!cat')
local pipe_write_ok = pcall(vim.cmd, 'write !cat >/dev/null')
assert(not append_write_ok)
assert(not filter_ok)
assert(not pipe_write_ok)
assert(vim.fn.filereadable(appended) == 0)
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), buffer_before_filter))
assert(read(encrypted) == saved_ciphertext)
assert(vim.b.sops_plain)
evidence('B2_append_write_ok', append_write_ok)
evidence('B2_append_file_created', vim.fn.filereadable(appended) == 1)
evidence('B2_filter_ok', filter_ok)
evidence('B2_pipe_write_ok', pipe_write_ok)
evidence('B2_buffer_preserved', vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), buffer_before_filter))
evidence('B2_ciphertext_unchanged', read(encrypted) == saved_ciphertext)
assert_no_plaintext_on_disk 'B2'

vim.cmd('saveas! ' .. vim.fn.fnameescape(safe_copy))
assert(read(safe_copy):find 'ENC%[AES256_GCM,data:CCCC%]')
assert(vim.b.sops_plain)

-- B8: после легального `:saveas` в другой sops-файл отказ альтернативной записи
-- обязан возвращать имя нового файла, а не того, с которого начинали. Иначе
-- расшифрованный буфер молча привязывается к чужому секрету и шифрует правки
-- в него.
local foreign_before_rename = read(encrypted)
local rename_alternate_ok = pcall(vim.cmd, 'write! ' .. vim.fn.fnameescape(alternate))
assert(not rename_alternate_ok)
assert(vim.fn.filereadable(alternate) == 0)
assert(vim.api.nvim_buf_get_name(0) == safe_copy)
local log_before_rename_write = read(log)
vim.cmd 'write!'
local log_after_rename_write = read(log):sub(#log_before_rename_write + 1)
assert(log_after_rename_write:find(safe_copy, 1, true))
assert(not log_after_rename_write:find(encrypted, 1, true))
assert(read(encrypted) == foreign_before_rename)
assert(not vim.bo.modified)
evidence('B8_alternate_write_ok', rename_alternate_ok)
evidence('B8_buffer_name', vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t'))
evidence('B8_encrypt_target', (log_after_rename_write:gsub('\n', ' | ')))
evidence('B8_foreign_unchanged', read(encrypted) == foreign_before_rename)
assert_no_plaintext_on_disk 'B8'

vim.api.nvim_set_current_line 'secret: unsaved-value'
vim.cmd.SopsLock()
assert(vim.b.sops_plain)
assert(vim.bo.modified)
vim.cmd 'SopsLock!'
assert(not vim.b.sops_plain)
assert(vim.api.nvim_get_current_line():find 'ENC%[AES256_GCM')
assert(not MiniStatusline.section_fileinfo({ trunc_width = 120 }):find 'SOPS:PLAIN')
vim.cmd.undo()
assert(vim.api.nvim_get_current_line():find 'ENC%[AES256_GCM')
assert(not vim.bo.modified)

local calls_before_ciphertext_write = line_count(log)
vim.cmd.write()
assert(line_count(log) == calls_before_ciphertext_write)

-- B4: отказ записи после `:saveas` обязан вернуть имя. Иначе расшифрованный
-- буфер остаётся привязан к имени вне sops_patterns и становится неуправляемым.
vim.cmd.SopsEdit()
assert(vim.b.sops_plain)
local unsafe_saveas_ok = pcall(vim.cmd, 'saveas! ' .. vim.fn.fnameescape(unsafe_saveas))
assert(not unsafe_saveas_ok)
assert(vim.fn.filereadable(unsafe_saveas) == 0)
assert(vim.api.nvim_buf_get_name(0) == safe_copy)
assert(vim.b.sops_plain)
evidence('B4_saveas_ok', unsafe_saveas_ok)
evidence('B4_file_created', vim.fn.filereadable(unsafe_saveas) == 1)
evidence('B4_buffer_name', vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':t'))
vim.cmd.SopsLock()
assert(not vim.b.sops_plain)
assert(vim.api.nvim_get_current_line():find 'ENC%[AES256_GCM')
evidence('B4_sopslock_after_saveas_plain', vim.b.sops_plain)
assert_no_plaintext_on_disk 'B4'

-- B1: расшифрованное состояние снимается содержимым, пришедшим с диска. Тест
-- проверяет не перечень способов перечитывания, а инвариант «маркер, флаг и
-- содержимое буфера говорят одно и то же»; перечислительный фикс на нём падает.
edit(reload)
vim.cmd.SopsEdit()
assert(vim.api.nvim_get_current_line() == 'secret: clear-value')
assert_plaintext_invariant 'decrypted'

-- Путь `autoread` закрыт структурно решением B10: расшифрованный буфер —
-- `acwrite`, а такие буферы Neovim по `:checktime` не перечитывает вовсе.
-- Проверяется здесь же, чтобы закрытие было видно, а не подразумевалось.
write(reload, 'secret: ENC[AES256_GCM,data:AAAA]\nreloaded: from-disk\n')
vim.cmd.checktime()
assert(vim.bo.buftype == 'acwrite')
assert(vim.api.nvim_buf_line_count(0) == 1)
assert(vim.b.sops_plain)
assert_plaintext_invariant 'checktime while decrypted'
evidence('B1_checktime_buftype', vim.bo.buftype)
evidence('B1_checktime_lines', vim.api.nvim_buf_line_count(0))
evidence('B1_checktime_plain', vim.b.sops_plain)

vim.cmd 'edit!'
assert(buffer_has_ciphertext())
assert(vim.api.nvim_buf_line_count(0) == 2)
assert(not vim.b.sops_plain)
assert(vim.bo.buftype == '')
assert_plaintext_invariant 'edit! reload'
evidence('B1_edit_bang_line', vim.api.nvim_get_current_line())
evidence('B1_edit_bang_plain', vim.b.sops_plain)
evidence('B1_edit_bang_marker', marker_shown())

-- А не расшифрованный буфер перечитывается как обычно: правило BufReadPost
-- обслуживает и этот путь, просто снимать ему нечего.
write(reload, 'secret: ENC[AES256_GCM,data:AAAA]\nreloaded: from-disk\nthird: line\n')
vim.cmd.checktime()
assert(vim.api.nvim_buf_line_count(0) == 3)
assert_plaintext_invariant 'checktime while encrypted'

-- B7: производное состояние — это не только флаг. Undo переживает
-- перезагрузку буфера, поэтому одного снятия флага мало: `u` возвращал
-- plaintext в буфер, у которого флага уже нет, а такой буфер `:w` пишет на
-- диск как есть. Обход матрицы переходов: после каждого из них и после `u` за
-- ним состояние обязано быть согласованным, а диск — без открытого текста.
edit(undo_reload)
assert_plaintext_invariant 'undo fixture opened'

vim.cmd.SopsEdit()
assert(vim.api.nvim_get_current_line() == 'secret: clear-value')
assert_plaintext_invariant 'SopsEdit'
vim.cmd.undo()
assert_plaintext_invariant 'undo after SopsEdit'

vim.cmd 'edit!'
assert(not vim.b.sops_plain)
assert_plaintext_invariant 'edit! reload'
vim.cmd.undo()
assert(not buffer_has_plaintext())
assert_plaintext_invariant 'undo after edit! reload'
evidence('B7_undo_after_edit_bang_line', vim.api.nvim_get_current_line())
evidence('B7_undo_after_edit_bang_plain', vim.b.sops_plain)
vim.cmd.write()
assert(read(undo_reload):find 'ENC%[AES256_GCM')
assert_no_plaintext_on_disk 'write after undo following edit!'
evidence('B7_disk_after_edit_bang_write', (read(undo_reload):gsub('\n', '\\n')))

vim.cmd.SopsEdit()
assert_plaintext_invariant 'SopsEdit before lock'
vim.cmd.SopsLock()
assert(not vim.b.sops_plain)
assert_plaintext_invariant 'SopsLock'
vim.cmd.undo()
assert(not buffer_has_plaintext())
assert_plaintext_invariant 'undo after SopsLock'
evidence('B7_undo_after_lock_line', vim.api.nvim_get_current_line())
evidence('B7_undo_after_lock_plain', vim.b.sops_plain)

write(undo_reload, 'secret: ENC[AES256_GCM,data:AAAA]\nreloaded: from-disk\n')
vim.cmd.checktime()
assert(vim.api.nvim_buf_line_count(0) == 2)
assert_plaintext_invariant 'checktime while encrypted'
vim.cmd.undo()
assert(not buffer_has_plaintext())
assert_plaintext_invariant 'undo after checktime'
evidence('B7_undo_after_checktime_line', vim.api.nvim_get_current_line())
evidence('B7_undo_after_checktime_plain', vim.b.sops_plain)
vim.cmd.write()
assert_no_plaintext_on_disk 'write after undo following checktime'
evidence('B7_disk_after_checktime_write', (read(undo_reload):gsub('\n', '\\n')))

vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'secret: changed-value'
vim.cmd.write()
assert_plaintext_invariant 'write while decrypted'
vim.cmd.undo()
assert(vim.b.sops_plain)
assert_plaintext_invariant 'undo after write while decrypted'
vim.cmd 'SopsLock!'
assert(not buffer_has_plaintext())
assert_plaintext_invariant 'SopsLock! after undo'
evidence('B7_disk_after_all_transitions', (read(undo_reload):gsub('\n', '\\n')))
assert_no_plaintext_on_disk 'B7'

-- B6: сам `.sops.yaml` под паттерны попадать не должен — секретов в нём нет,
-- а следы он гасил на всю сессию и предлагал `:SopsEdit` над открытым текстом.
local config_notifications = {}
local notify_before_config = vim.notify
vim.notify = function(message) table.insert(config_notifications, message) end
edit(sops_config)
vim.notify = notify_before_config
assert(not table.concat(config_notifications, '\n'):find('sops: следы', 1, true))
assert(vim.bo.swapfile)
assert(vim.bo.undofile)
local config_edit_ok = pcall(vim.cmd.SopsEdit)
assert(not config_edit_ok)
assert(not vim.b.sops_plain)
evidence('B6_open_notifications', #config_notifications)
evidence('B6_swapfile', vim.bo.swapfile)
evidence('B6_undofile', vim.bo.undofile)
evidence('B6_sops_edit_ok', config_edit_ok)
assert_no_plaintext_on_disk 'B6'

edit(broken)
local broken_before = read(broken)
pcall(vim.cmd.SopsEdit)
assert(read(broken) == broken_before)
assert(vim.api.nvim_get_current_line() == 'FAIL_DECRYPT')
assert(not vim.b.sops_plain)

edit(no_rule)
vim.cmd.SopsEdit()
assert(vim.b.sops_plain)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'TOKEN=clear-value' })
assert(not pcall(vim.cmd.write))
assert(vim.fn.filereadable(no_rule) == 0)
assert(vim.bo.modified)

-- B10: решение владельца — пока буфер помечен plaintext, языковые серверы к
-- нему не прицеплены. Проверяется не перечнем серверов (он разъехался бы с
-- таблицей `servers` на первом новом языке), а тем, что ни одно сообщение
-- протокола не унесло расшифрованное значение: сервер поднимается в этом же
-- процессе и записывает всё, что ему прислали.
local lsp_messages = {}
local defer_initialize = false
local function sops_probe_server(_)
  local closing = false
  local function record(method, params) table.insert(lsp_messages, method .. ' ' .. vim.json.encode(params or vim.empty_dict())) end
  return {
    request = function(method, params, callback)
      record(method, params)
      if method == 'initialize' then
        local reply = function() callback(nil, { capabilities = { textDocumentSync = { openClose = true, change = 1 } } }) end
        if defer_initialize then
          vim.schedule(reply)
        else
          reply()
        end
      elseif method == 'shutdown' then
        callback(nil, nil)
      end
      return true, 1
    end,
    notify = function(method, params)
      record(method, params)
      if method == 'exit' then closing = true end
      return true
    end,
    is_closing = function() return closing end,
    terminate = function() closing = true end,
  }
end

local function assert_no_plaintext_in_lsp_traffic(label)
  local traffic = table.concat(lsp_messages, '\n')
  for _, sentinel in ipairs(plaintext_sentinels) do
    assert(not traffic:find(sentinel), label .. ': plaintext reached a language server')
  end
end

vim.lsp.config('sopsprobe', { cmd = sops_probe_server, filetypes = { 'yaml' }, root_dir = project })
vim.lsp.enable 'sopsprobe'

edit(lsp_probe)
vim.wait(1000, function() return #vim.lsp.get_clients { bufnr = 0 } > 0 end)
assert(#vim.lsp.get_clients { bufnr = 0 } > 0)
assert(table.concat(lsp_messages, '\n'):find('textDocument/didOpen', 1, true))
evidence('B10_clients_on_ciphertext', #vim.lsp.get_clients { bufnr = 0 })

vim.cmd.SopsEdit()
vim.wait(200)
assert(vim.b.sops_plain)
assert(vim.bo.filetype == 'yaml')
assert(vim.bo.buftype == 'acwrite')
assert(#vim.lsp.get_clients { bufnr = 0 } == 0)
assert_no_plaintext_in_lsp_traffic 'after SopsEdit'
vim.api.nvim_set_current_line 'secret: changed-value'
vim.cmd.write()
vim.wait(200)
assert(#vim.lsp.get_clients { bufnr = 0 } == 0)
assert_no_plaintext_in_lsp_traffic 'after write'
evidence('B10_filetype_while_plain', vim.bo.filetype)
evidence('B10_buftype_while_plain', vim.bo.buftype)
evidence('B10_clients_while_plain', #vim.lsp.get_clients { bufnr = 0 })

vim.cmd 'SopsLock!'
vim.wait(1000, function() return #vim.lsp.get_clients { bufnr = 0 } > 0 end)
assert(vim.bo.buftype == '')
assert(#vim.lsp.get_clients { bufnr = 0 } > 0)
assert_no_plaintext_in_lsp_traffic 'after SopsLock'
evidence('B10_buftype_after_lock', vim.bo.buftype)
evidence('B10_clients_after_lock', #vim.lsp.get_clients { bufnr = 0 })
evidence('B10_lsp_messages', #lsp_messages)

-- Подстраховка `LspAttach` проверяется отдельно и честно: клиент прицепляется
-- к расшифрованному буферу насильно, минуя гейт `buftype`. Обработчик обязан
-- отцепить его, но `didOpen` к этому моменту уже ушёл — поэтому дальше
-- строгая проверка трафика к нему не применяется, а её граница зафиксирована.
local strict_traffic_end = #lsp_messages
vim.cmd.SopsEdit()
assert(vim.b.sops_plain)
local probe_client = vim.lsp.get_clients({ name = 'sopsprobe' })[1]
assert(probe_client)
vim.lsp.buf_attach_client(0, probe_client.id)
vim.wait(1000, function() return #vim.lsp.get_clients { bufnr = 0 } == 0 end)
assert(#vim.lsp.get_clients { bufnr = 0 } == 0)
local late_traffic = table.concat(vim.list_slice(lsp_messages, strict_traffic_end + 1), '\n')
assert(late_traffic:find('textDocument/didOpen', 1, true))
assert(late_traffic:find('textDocument/didClose', 1, true))
evidence('B10_backstop_clients_after_forced_attach', #vim.lsp.get_clients { bufnr = 0 })
evidence('B10_backstop_did_close', late_traffic:find('textDocument/didClose', 1, true) ~= nil)
vim.cmd 'SopsLock!'

-- Клиент, который ещё поднимается, уже прицеплен к буферу, но `get_clients`
-- по умолчанию его не показывает; `didOpen` он отправит сразу после initialize
-- — то есть уже поверх расшифрованного текста. Поэтому снятие идёт по списку с
-- `_uninitialized`, и проверяется это отдельно: подстраховка `LspAttach` такой
-- клиент тоже отцепит, но уже после того, как секрет отправлен.
defer_initialize = true
vim.lsp.config('sopsprobelate', { cmd = sops_probe_server, filetypes = { 'yaml' }, root_dir = project })
vim.lsp.enable 'sopsprobelate'
edit(lsp_late)
local visible_clients = #vim.lsp.get_clients { bufnr = 0 }
local attached_clients = #vim.lsp.get_clients { bufnr = 0, _uninitialized = true }
assert(attached_clients > visible_clients)
evidence('B10_late_visible_clients', visible_clients)
evidence('B10_late_attached_clients', attached_clients)
vim.cmd.SopsEdit()
assert(vim.b.sops_plain)
assert(#vim.lsp.get_clients { bufnr = 0, _uninitialized = true } == 0)
vim.wait(500)
assert(#vim.lsp.get_clients { bufnr = 0, _uninitialized = true } == 0)
assert_no_plaintext_in_lsp_traffic 'uninitialized client'
evidence('B10_late_clients_after_edit', #vim.lsp.get_clients { bufnr = 0, _uninitialized = true })
defer_initialize = false
vim.cmd 'SopsLock!'

assert_no_plaintext_on_disk 'B10'

-- C1: предсказуемый временный pathname позволял заранее подложить симлинк:
-- `writefile` шёл по нему и перезаписывал посторонний файл ещё до rename.
-- Эксклюзивный уникальный tempfile вообще не должен трогать этот pathname.
edit(symlink_atomic)
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'secret: changed-value'
local symlink_victim_before = read(symlink_victim)
local predictable_temporary = symlink_atomic .. '.sops-nvim.tmp'
assert(vim.uv.fs_symlink(symlink_victim, predictable_temporary))
local symlink_write_ok = pcall(vim.cmd.write)
assert(symlink_write_ok)
assert(read(symlink_victim) == symlink_victim_before)
assert(vim.uv.fs_readlink(predictable_temporary) == symlink_victim)
assert(read(symlink_atomic):find 'ENC%[AES256_GCM,data:CCCC%]')
evidence('C1_symlink_write_ok', symlink_write_ok)
evidence('C1_symlink_victim_unchanged', read(symlink_victim) == symlink_victim_before)
evidence('C1_symlink_untouched', vim.uv.fs_readlink(predictable_temporary) == symlink_victim)
assert(vim.uv.fs_unlink(predictable_temporary))
vim.cmd 'SopsLock!'
assert_no_plaintext_on_disk 'C1 symlink'

-- C2: объём больше типичной ёмкости pipe проверяет, что родитель одновременно
-- пишет stdin и вычитывает stdout, а fake sops ниже дополнительно требует FIFO
-- и непосредственного родителя nvim.
edit(pipe_transport)
vim.cmd.SopsEdit()
local transport_lines = {}
for index = 1, 5000 do
  transport_lines[index] = ('secret_%d: changed-value'):format(index)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, transport_lines)
vim.cmd.write()
local transport_ciphertext = read(pipe_transport)
assert(not transport_ciphertext:find 'changed%-value')
assert(transport_ciphertext:find 'ENC%[AES256_GCM,data:CCCC%]')
assert(not vim.bo.modified)
evidence('C2_large_input_lines', #transport_lines)
evidence('C2_large_ciphertext_size', #transport_ciphertext)
evidence('C2_large_plaintext_on_disk', transport_ciphertext:find 'changed%-value' ~= nil)
vim.cmd 'SopsLock!'
assert_no_plaintext_on_disk 'C2 transport'

-- D1: замена принимается не по отсутствию известных ошибок, а только по
-- доказанному успеху. Оба результата ниже имеют code=0 и непустой stdout:
-- первый ребёнок успевает напечатать обрывок и погибает от SIGTERM, второй
-- завершается сам, но печатает не SOPS-документ.
local function assert_incomplete_encrypt_rejected(path, mode, label)
  edit(path)
  vim.cmd.SopsEdit()
  vim.api.nvim_set_current_line 'secret: changed-value'
  local before = read(path)
  local notifications = {}
  local previous_notify = vim.notify
  vim.notify = function(message) table.insert(notifications, message) end
  vim.env[mode] = '1'
  local write_ok = pcall(vim.cmd.write)
  vim.env[mode] = nil
  vim.notify = previous_notify

  assert(not write_ok, label .. ': incomplete output was accepted')
  assert(read(path) == before, label .. ': ciphertext changed')
  assert(vim.bo.modified, label .. ': buffer lost modified state')
  assert(table.concat(notifications, '\n'):find('sops encrypt failed', 1, true))
  evidence('D1_' .. label .. '_write_ok', write_ok)
  evidence('D1_' .. label .. '_ciphertext_unchanged', read(path) == before)
  evidence('D1_' .. label .. '_modified', vim.bo.modified)
  evidence('D1_' .. label .. '_notification', table.concat(notifications, ' | '))
  vim.cmd 'SopsLock!'
  assert_no_plaintext_on_disk('D1 ' .. label)
end

assert_incomplete_encrypt_rejected(signalled, 'SOPS_TEST_SIGNAL_ENCRYPT', 'signal')
assert_incomplete_encrypt_rejected(nonsops, 'SOPS_TEST_NONSOPS_ENCRYPT', 'nonsops')

for _, fixture in ipairs {
  { label = 'yaml', path = signalled },
  { label = 'json', path = valid_json },
  { label = 'tfvars', path = valid_tfvars },
  { label = 'env', path = valid_env },
} do
  edit(fixture.path)
  vim.cmd.SopsEdit()
  vim.api.nvim_set_current_line 'secret: changed-value'
  local valid_write_ok = pcall(vim.cmd.write)
  assert(valid_write_ok, fixture.label .. ': complete sops output was rejected')
  assert(not vim.bo.modified)
  evidence('D1_' .. fixture.label .. '_complete_output_accepted', valid_write_ok)
  vim.cmd 'SopsLock!'
  assert_no_plaintext_on_disk('D1 valid ' .. fixture.label)
end

-- D2: проверка стоит на границе «содержимое буфера → внешний процесс», поэтому
-- тест подсовывает conform новое имя форматтера для каждого поддерживаемого
-- типа. Перечень prettier/terraform_fmt/shfmt такой probe не поймает.
vim.cmd 'Lazy load conform.nvim'
local conform = require 'conform'
conform.formatters.d2_unlisted_probe = {
  command = root .. '/fake-bin/d2-unlisted-probe',
  stdin = true,
}
for _, fixture in ipairs(format_fixtures) do
  conform.formatters_by_ft[fixture.filetype] = { 'd2_unlisted_probe' }
end

local format_mapping = vim.fn.maparg(vim.g.mapleader .. 'f', 'n', false, true)
assert(type(format_mapping.callback) == 'function')
local foreign_log = assert(vim.env.SOPS_TEST_FOREIGN_LOG)

for _, fixture in ipairs(format_fixtures) do
  edit(fixture.path)
  vim.cmd.SopsEdit()
  assert(vim.bo.filetype == fixture.filetype)
  vim.api.nvim_set_current_line 'secret: changed-value'
  local calls_before_format = line_count(foreign_log)
  local format_ok, format_error = pcall(format_mapping.callback)
  if format_ok then vim.wait(300, function() return line_count(foreign_log) > calls_before_format end, 10) end
  local foreign_processes = line_count(foreign_log) - calls_before_format
  assert(not format_ok, fixture.label .. ': manual formatting was not rejected')
  assert(tostring(format_error):find('external process blocked', 1, true))
  assert(foreign_processes == 0, fixture.label .. ': formatter process was started')
  assert(vim.bo.modified)
  evidence('D2_' .. fixture.label .. '_format_ok', format_ok)
  evidence('D2_' .. fixture.label .. '_foreign_processes', foreign_processes)
  evidence('D2_' .. fixture.label .. '_error', format_error)
  vim.cmd 'SopsLock!'
  assert_no_plaintext_on_disk('D2 ' .. fixture.label)
end

edit(ordinary_format)
local ordinary_calls_before = line_count(foreign_log)
local ordinary_format_ok = pcall(format_mapping.callback)
vim.wait(1000, function() return line_count(foreign_log) > ordinary_calls_before end, 10)
local ordinary_foreign_processes = line_count(foreign_log) - ordinary_calls_before
assert(ordinary_format_ok)
assert(ordinary_foreign_processes == 1)
evidence('D2_ordinary_format_ok', ordinary_format_ok)
evidence('D2_ordinary_foreign_processes', ordinary_foreign_processes)
vim.cmd 'bwipeout!'

-- B9: запись перестала обрезать цель на месте. Отказ на полпути обязан
-- оставлять прежний файл байт в байт и не оставлять временного файла.
edit(atomic)
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line 'secret: changed-value'
local atomic_before = read(atomic)
assert(vim.uv.fs_chmod(project, tonumber('500', 8)))
local atomic_write_ok = pcall(vim.cmd.write)
assert(vim.uv.fs_chmod(project, tonumber('700', 8)))
assert(not atomic_write_ok)
assert(read(atomic) == atomic_before)
assert(vim.bo.modified)
assert(vim.fn.glob(project .. '/*.tmp') == '')
evidence('B9_write_ok', atomic_write_ok)
evidence('B9_target_unchanged', read(atomic) == atomic_before)
evidence('B9_target_size', vim.fn.getfsize(atomic))
evidence('B9_modified', vim.bo.modified)
evidence('B9_temporary_left', vim.fn.glob(project .. '/*.tmp'))
vim.cmd 'SopsLock!'
vim.cmd.write()
assert(read(atomic) == atomic_before)
evidence('B9_recovered_write', read(atomic) == atomic_before)
assert_no_plaintext_on_disk 'B9'

-- ExampleOrg/demo-service selects its dedicated identity at the process boundary.
-- The unrelated project is the negative half of the rule: both inherited age
-- variables must reach sops unchanged, so broad path matching fails here.
local saved_identity_environment = {
  HOME = vim.env.HOME,
  SOPS_AGE_KEY_FILE = vim.env.SOPS_AGE_KEY_FILE,
  SOPS_AGE_KEY = vim.env.SOPS_AGE_KEY,
}
vim.env.HOME = identity_home
vim.env.SOPS_AGE_KEY_FILE = assert(vim.env.SOPS_TEST_INHERITED_KEY_FILE)
vim.env.SOPS_AGE_KEY = assert(vim.env.SOPS_TEST_INHERITED_KEY)

local function assert_identity_route(path, label)
  edit(path)
  vim.cmd.SopsEdit()
  assert(vim.b.sops_plain, label .. ': decrypt route failed')
  vim.api.nvim_set_current_line 'secret: changed-value'
  local write_ok = pcall(vim.cmd.write)
  assert(write_ok, label .. ': encrypt route failed')
  assert(not vim.bo.modified, label .. ': successful write left buffer modified')
  assert(not read(path):find('changed-value', 1, true), label .. ': plaintext reached disk')
  vim.cmd 'SopsLock!'
end

assert_identity_route(exampleorg_route, 'exampleorg')
assert_identity_route(other_route, 'other project')

-- Граница проекта — это реальное расположение файла, а не текстовый префикс
-- пути. Перечислять запрещённые формы бесполезно, поэтому проверяются обе
-- стороны каждого шва: сосед по префиксу, `..`, симлинк наружу и внутрь, и
-- отдельно те же симлинки с ещё не существующим файлом — у него `realpath`
-- не отвечает вовсе, и лексический fallback принимал нерезолвнутый симлинк
-- за доказательство места.
local boundary_cases = {
  { label = 'prefix_neighbor', path = exampleorg_root .. '-neighbor/route.sops.yml', route = 'inherited', actions = 'decrypt,encrypt' },
  { label = 'parent_out', path = exampleorg_root .. '/../demo-service-neighbor/route.sops.yml', route = 'inherited', actions = 'decrypt,encrypt' },
  { label = 'parent_in', path = exampleorg_root .. '/inner/../route.sops.yml', route = 'exampleorg', actions = 'decrypt,encrypt' },
  { label = 'symlink_out', path = exampleorg_root .. '/escape/escaped.sops.yml', route = 'inherited', actions = 'decrypt,encrypt' },
  { label = 'symlink_in', path = outside_root .. '/into-project/entered.sops.yml', route = 'exampleorg', actions = 'decrypt,encrypt' },
  { label = 'new_symlink_out', path = exampleorg_root .. '/escape/fresh.sops.yml', route = 'inherited', actions = 'encrypt' },
  { label = 'new_symlink_in', path = outside_root .. '/into-project/fresh.sops.yml', route = 'exampleorg', actions = 'encrypt' },
}

for _, boundary in ipairs(boundary_cases) do
  vim.env.SOPS_TEST_CASE = boundary.label
  assert_identity_route(boundary.path, boundary.label)
  vim.env.SOPS_TEST_CASE = nil

  local calls = 0
  local actions = {}
  for action, route in read(log):gmatch('identity_case|([^|\n]+)|' .. vim.pesc(boundary.label) .. '|([^|\n]+)') do
    calls = calls + 1
    table.insert(actions, action)
    assert(route == boundary.route, boundary.label .. ': ' .. action .. ' took the ' .. route .. ' identity')
  end
  assert(table.concat(actions, ',') == boundary.actions, boundary.label .. ': wrong sops actions')
  evidence('identity_boundary_' .. boundary.label, boundary.route .. '|' .. calls)
end

-- То же правило, но без Neovim в середине. Сквозной прогон выше зелёный даже
-- на решении по текстовому префиксу: имя буфера приходит уже резолвнутым —
-- Neovim 0.11 разрешает симлинки сам, в том числе для ещё не существующего
-- файла. Опираться на это свойство вызывающего нельзя, поэтому решение
-- проверяется прямым вызовом на нерезолвнутых путях; функция берётся из
-- живого конфига обходом upvalue, а не копией.
local function config_function(name)
  local queue = {}
  local seen = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds { event = 'BufWriteCmd', group = 'sops-buffer-edit' }) do
    if type(autocmd.callback) == 'function' then table.insert(queue, autocmd.callback) end
  end
  while #queue > 0 do
    local fn = table.remove(queue, 1)
    if not seen[fn] then
      seen[fn] = true
      local index = 1
      while true do
        local upvalue, value = debug.getupvalue(fn, index)
        if not upvalue then break end
        if type(value) == 'function' then
          if upvalue == name then return value end
          table.insert(queue, value)
        end
        index = index + 1
      end
    end
  end
end

local exampleorg_identity = assert(config_function 'configured_sops_identity', 'routing function not reachable')
local identity_file = identity_home .. '/.config/exampleorg-demo-service/age/identity.txt'
local direct_cases = {
  { label = 'direct_root_file', path = exampleorg_route, routed = true },
  { label = 'direct_prefix_neighbor', path = exampleorg_root .. '-neighbor/route.sops.yml', routed = false },
  { label = 'direct_parent_out', path = exampleorg_root .. '/../demo-service-neighbor/route.sops.yml', routed = false },
  { label = 'direct_parent_in', path = exampleorg_root .. '/inner/../route.sops.yml', routed = true },
  { label = 'direct_symlink_out', path = exampleorg_root .. '/escape/escaped.sops.yml', routed = false },
  { label = 'direct_symlink_in', path = outside_root .. '/into-project/entered.sops.yml', routed = true },
  { label = 'direct_new_symlink_out', path = exampleorg_root .. '/escape/unwritten.sops.yml', routed = false },
  { label = 'direct_new_symlink_in', path = outside_root .. '/into-project/unwritten.sops.yml', routed = true },
  {
    label = 'direct_absent_parent_in',
    path = exampleorg_root .. '/absent/deeper/unwritten.sops.yml',
    probe = exampleorg_root .. '/absent',
    realpath_error = 'ENOENT',
    lstat_error = 'ENOENT',
    routed = true,
  },
  {
    label = 'direct_dangling_directory',
    path = exampleorg_root .. '/dangling/unwritten.sops.yml',
    probe = exampleorg_root .. '/dangling',
    realpath_error = 'ENOENT',
    lstat_present = true,
    routed = false,
  },
  {
    label = 'direct_dangling_file',
    path = exampleorg_root .. '/dangling-file.sops.yml',
    probe = exampleorg_root .. '/dangling-file.sops.yml',
    realpath_error = 'ENOENT',
    lstat_present = true,
    routed = false,
  },
  {
    label = 'direct_locked_directory',
    path = exampleorg_root .. '/locked/sub/unwritten.sops.yml',
    probe = exampleorg_root .. '/locked/sub',
    realpath_error = 'EACCES',
    lstat_error = 'EACCES',
    routed = false,
  },
  {
    label = 'direct_symlink_loop',
    path = exampleorg_root .. '/loop-a/unwritten.sops.yml',
    probe = exampleorg_root .. '/loop-a/unwritten.sops.yml',
    realpath_error = 'ELOOP',
    lstat_error = 'ELOOP',
    routed = false,
  },
  { label = 'direct_absent_parent_out', path = outside_root .. '/absent/deeper/unwritten.sops.yml', routed = false },
  { label = 'direct_other_project', path = other_route, routed = false },
  { label = 'direct_new_symlink_parent_out', path = exampleorg_root .. '/escape/../unwritten.sops.yml', routed = false },
  { label = 'direct_new_symlink_parent_in', path = outside_root .. '/into-project/../unwritten.sops.yml', routed = true },
}

local direct_failures = {}
for _, direct in ipairs(direct_cases) do
  if direct.probe then
    local resolved, realpath_error = vim.uv.fs_realpath(direct.probe)
    assert(
      resolved == nil and realpath_error and realpath_error:match('^' .. direct.realpath_error .. ':'),
      direct.label .. ': expected realpath ' .. direct.realpath_error .. ', got ' .. tostring(realpath_error)
    )
    local entry, lstat_error = vim.uv.fs_lstat(direct.probe)
    if direct.lstat_present then
      assert(entry ~= nil, direct.label .. ': lstat must find the symlink: ' .. tostring(lstat_error))
    else
      assert(
        entry == nil and lstat_error and lstat_error:match('^' .. direct.lstat_error .. ':'),
        direct.label .. ': expected lstat ' .. direct.lstat_error .. ', got ' .. tostring(lstat_error)
      )
    end
    evidence('identity_precondition_' .. direct.label, direct.realpath_error .. '|lstat=' .. (direct.lstat_present and 'present' or direct.lstat_error))
  end
  if direct.path:find('unwritten.sops.yml', 1, true) then
    assert(vim.uv.fs_lstat(direct.path) == nil, direct.label .. ': path must remain absent')
    assert(vim.uv.fs_realpath(direct.path) == nil, direct.label .. ': realpath must fail')
  end
  local identity = exampleorg_identity(direct.path)
  if (identity ~= nil) ~= direct.routed then
    table.insert(direct_failures, direct.label .. ': routed=' .. tostring(identity ~= nil))
  elseif direct.routed and identity ~= identity_file then
    table.insert(direct_failures, direct.label .. ': wrong identity file')
  end
  evidence('identity_' .. direct.label, tostring(identity ~= nil))
end
assert(#direct_failures == 0, table.concat(direct_failures, '; '))

-- An unresolved project root must not acquire files through lexical matching.
vim.env.HOME = root .. '/absent-home'
local absent_root_path = vim.env.HOME .. '/ExampleOrg/demo-service/unwritten.sops.yml'
assert(vim.uv.fs_realpath(vim.env.HOME .. '/ExampleOrg/demo-service') == nil)
assert(exampleorg_identity(absent_root_path) == nil, 'direct_absent_root: routed=true')
evidence('identity_direct_absent_root', false)
vim.env.HOME = saved_identity_environment.HOME
vim.env.SOPS_AGE_KEY_FILE = saved_identity_environment.SOPS_AGE_KEY_FILE
vim.env.SOPS_AGE_KEY = saved_identity_environment.SOPS_AGE_KEY

local calls = read(log)
assert(calls:find(project .. '|decrypt|'))
assert(calls:find(project .. '|encrypt|'))
assert(calls:find('%-%-filename%-override ' .. vim.pesc(encrypted)))
for _, expected_route in ipairs {
  'identity_route|decrypt|exampleorg',
  'identity_route|encrypt|exampleorg',
  'identity_route|decrypt|inherited',
  'identity_route|encrypt|inherited',
} do
  assert(calls:find(expected_route, 1, true), 'missing route: ' .. expected_route)
end
evidence('identity_exampleorg_decrypt', true)
evidence('identity_exampleorg_encrypt', true)
evidence('identity_other_decrypt_inherited', true)
evidence('identity_other_encrypt_inherited', true)
local c2_transport = calls:match 'C2_transport|([^\n]+)'
assert(c2_transport == 'stdin=pipe|parent=nvim')
evidence('C2_transport', c2_transport)
assert_no_plaintext_on_disk 'suite end'
