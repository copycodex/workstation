-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

---@module 'lazy'
---@type LazySpec
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  ---@module 'neo-tree'
  ---@type neotree.Config
  opts = {
    enable_git_status = true,
    default_component_configs = {
      name = {
        use_git_status_colors = true,
      },
      git_status = {
        symbols = {
          added = 'A',
          deleted = 'D',
          modified = 'M',
          renamed = 'R',
          untracked = '?',
          ignored = 'I',
          unstaged = 'U',
          staged = 'S',
          conflict = '!',
        },
        align = 'right',
      },
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['sg'] = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)

            require('telescope.builtin').live_grep {
              cwd = directory,
              prompt_title = 'Grep in ' .. vim.fn.fnamemodify(directory, ':~:.'),
            }
          end,
        },
      },
    },
  },
  config = function(_, opts)
    require('neo-tree').setup(opts)

    local function set_git_colors()
      -- Close to the file-status palette used by JetBrains Darcula.
      vim.api.nvim_set_hl(0, 'NeoTreeGitModified', { fg = '#6897BB' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitAdded', { fg = '#629755' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitUntracked', { fg = '#D1675A' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitDeleted', { fg = '#CC7832' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitRenamed', { fg = '#BBB529' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitConflict', { fg = '#FF6B68', bold = true })
      vim.api.nvim_set_hl(0, 'NeoTreeGitIgnored', { fg = '#606366' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitStaged', { fg = '#629755' })
      vim.api.nvim_set_hl(0, 'NeoTreeGitUnstaged', { fg = '#6897BB' })
    end

    set_git_colors()
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('neo-tree-git-colors', { clear = true }),
      callback = set_git_colors,
    })
  end,
}
