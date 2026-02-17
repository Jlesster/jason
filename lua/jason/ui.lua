-- lua/jason/ui.lua
-- This is a simplified version - copy your Marvin ui.lua for full features
local M = {}

M.backend = nil

function M.init()
  local config = require('jason').config
  M.backend = config.ui_backend == 'auto' and M.detect_backend() or config.ui_backend
end

function M.detect_backend()
  if pcall(require, 'snacks') then
    return 'snacks'
  elseif pcall(require, 'dressing') then
    return 'dressing'
  else
    return 'builtin'
  end
end

function M.select(items, opts, callback)
  opts = opts or {}

  if M.backend == 'snacks' then
    local ok, snacks = pcall(require, 'snacks')
    if ok and snacks.picker then
      -- Use snacks picker
      return
    end
  end

  -- Fallback to vim.ui.select
  local display_items = {}
  for _, item in ipairs(items) do
    if type(item) == 'table' and not item.is_separator then
      local icon = item.icon and (item.icon .. ' ') or ''
      local desc = item.desc and (' • ' .. item.desc) or ''
      table.insert(display_items, icon .. item.label .. desc)
    elseif not (type(item) == 'table' and item.is_separator) then
      table.insert(display_items, tostring(item))
    end
  end

  vim.ui.select(display_items, {
    prompt = opts.prompt or 'Select',
    format_item = function(item) return item end,
  }, function(choice, idx)
    if choice and items[idx] then
      callback(items[idx])
    else
      callback(nil)
    end
  end)
end

function M.input(opts, callback)
  opts = opts or {}

  vim.ui.input({
    prompt = opts.prompt or 'Input: ',
    default = opts.default or '',
  }, callback)
end

function M.notify(message, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO

  if M.backend == 'snacks' then
    local ok, snacks = pcall(require, 'snacks')
    if ok and snacks.notify then
      snacks.notify(message, {
        level = M.level_to_snacks(level),
        title = opts.title or 'Jason',
      })
      return
    end
  end

  vim.notify(message, level, {
    title = opts.title or 'Jason',
  })
end

function M.level_to_snacks(level)
  if level == vim.log.levels.ERROR then return 'error' end
  if level == vim.log.levels.WARN then return 'warn' end
  if level == vim.log.levels.INFO then return 'info' end
  return 'debug'
end

return M
