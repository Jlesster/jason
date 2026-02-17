-- lua/jason/keymaps.lua
local M = {}

function M.setup(config)
  local keymaps = config.keymaps or {}

  if vim.tbl_count(keymaps) == 0 then
    return
  end

  if keymaps.dashboard then
    vim.keymap.set('n', keymaps.dashboard, ':Jason<CR>', {
      desc = 'Open Jason Dashboard',
      silent = true,
    })
  end

  if keymaps.build then
    vim.keymap.set('n', keymaps.build, ':JasonBuild<CR>', {
      desc = 'Build project',
      silent = true,
    })
  end

  if keymaps.run then
    vim.keymap.set('n', keymaps.run, ':JasonRun<CR>', {
      desc = 'Run project',
      silent = true,
    })
  end

  if keymaps.test then
    vim.keymap.set('n', keymaps.test, ':JasonTest<CR>', {
      desc = 'Run tests',
      silent = true,
    })
  end

  if keymaps.clean then
    vim.keymap.set('n', keymaps.clean, ':JasonClean<CR>', {
      desc = 'Clean build artifacts',
      silent = true,
    })
  end
end

return M
