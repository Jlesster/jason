-- lua/jason/init.lua
local M = {}

M.config = {}

function M.setup(opts)
  local config = require('jason.config')
  M.config = config.setup(opts)

  local commands = require('jason.commands')
  commands.register()

  local keymaps = require('jason.keymaps')
  keymaps.setup(M.config)

  M.setup_autocommands()

  local ui = require('jason.ui')
  ui.init()
end

function M.setup_autocommands()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'java', 'rust', 'go', 'c', 'cpp' },
    callback = function()
      local detector = require('jason.detector')
      detector.detect()
    end,
  })
end

return M
