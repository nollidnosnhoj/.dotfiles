-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
    'apple1417/neo_tree_submodules',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    sources = {
      'filesystem',
      'buffers',
      'git_status',
      'neo_tree_submodules'
    },
    source_selector = {
      sources = {
        { source = 'filesystem' },
        { source = 'buffers' },
        { source = 'git_status' },
        { source = 'neo_tree_submodules' },
      },
    },
    filesystem = {
      filtered_items = {
        visible = false,
        hide_gitignored = true,
        hide_dotfiles = false,
        hide_by_name = {
          '.github',
          '.gitignore',
          'package-lock.json',
          '.changeset',
          '.prettierrc.json',
        },
        never_show = { '.git' },
      },
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
