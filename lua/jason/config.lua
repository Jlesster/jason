-- lua/jason/config.lua
local M = {}

M.defaults = {
  ui_backend = 'auto',

  terminal = {
    position = 'float', -- float, split, vsplit, background
    size = 0.4,
    close_on_success = false,
  },

  quickfix = {
    auto_open = true,
    height = 10,
  },

  keymaps = {
    dashboard = '<leader>jb',
    build = '<leader>jc',
    run = '<leader>jr',
    test = '<leader>jt',
    clean = '<leader>jx',
  },

  -- Language-specific configs
  java = {
    build_tool = 'auto',        -- auto, maven, gradle, javac
    main_class_finder = 'auto', -- auto, prompt
  },

  rust = {
    build_tool = 'cargo',
    profile = 'dev', -- dev, release
  },

  go = {
    build_tool = 'go',
  },

  cpp = {
    build_tool = 'auto', -- auto, cmake, make, gcc
    compiler = 'g++',
    standard = 'c++17',
  },
}

function M.setup(opts)
  return vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
