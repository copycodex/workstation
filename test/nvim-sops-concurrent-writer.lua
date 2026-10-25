local root = assert(vim.env.SOPS_TEST_ROOT)
local barrier = assert(vim.env.SOPS_TEST_BARRIER)
local writer = assert(vim.env.SOPS_TEST_WRITER)
local target = root .. '/project/concurrent.sops.yml'

-- Оба процесса доходят до rename только после того, как каждый завершил
-- запись своего tempfile. У фиксированного pathname первый rename забирает
-- общий файл, и второй писатель остаётся без своего источника. Уникальные
-- эксклюзивно созданные файлы позволяют завершиться обоим.
local fs_rename = vim.uv.fs_rename
vim.uv.fs_rename = function(source, destination)
  local file = assert(io.open(barrier, 'a'))
  assert(file:write(writer .. '\n'))
  file:close()
  assert(vim.wait(5000, function() return #vim.fn.readfile(barrier) == 2 end, 10), 'concurrent writer barrier timed out')
  return fs_rename(source, destination)
end

vim.cmd('edit ' .. vim.fn.fnameescape(target))
vim.cmd.SopsEdit()
vim.api.nvim_set_current_line('secret: changed-value-' .. writer)
vim.cmd 'write!'
vim.cmd 'quit!'
