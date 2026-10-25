-- Install before init.lua: startup can use the clipboard before -l runs.
-- Keep independent + and * state so SOPS register cleanup is exercised.
local clipboard = { ['+'] = { {}, 'v' }, ['*'] = { {}, 'v' } }
local copy = {}
local paste = {}
for _, register in ipairs { '+', '*' } do
  copy[register] = function(lines, regtype) clipboard[register] = { vim.deepcopy(lines), regtype } end
  paste[register] = function() return unpack(clipboard[register]) end
end
vim.g.clipboard = { name = 'sops-test', copy = copy, paste = paste, cache_enabled = 0 }
