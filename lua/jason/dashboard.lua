-- lua/jason/dashboard.lua
local M = {}

function M.show()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected in current directory', vim.log.levels.WARN)
    return
  end

  local menu_items = M.build_menu(project)
  local ui = require('jason.ui')

  local prompt = string.format('JASON » %s [%s]',
    vim.fn.fnamemodify(project.root, ':t'),
    project.language:upper()
  )

  ui.select(menu_items, {
    prompt = prompt,
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then
      M.handle_action(choice.id, project)
    end
  end)
end

function M.build_menu(project)
  local items = {}

  -- Build & Run section
  table.insert(items, {
    id = 'separator_build',
    label = 'Build & Run',
    is_separator = true
  })

  table.insert(items, {
    id = 'build',
    label = 'Build Project',
    icon = '⚙️',
    desc = 'Compile sources',
    shortcut = 'b'
  })

  table.insert(items, {
    id = 'run',
    label = 'Run Project',
    icon = '▶️',
    desc = 'Execute application',
    shortcut = 'r'
  })

  table.insert(items, {
    id = 'build_run',
    label = 'Build & Run',
    icon = '🚀',
    desc = 'Build then execute',
    shortcut = 'R'
  })

  -- Testing section
  table.insert(items, {
    id = 'separator_test',
    label = 'Testing',
    is_separator = true
  })

  table.insert(items, {
    id = 'test',
    label = 'Run Tests',
    icon = '🧪',
    desc = 'Execute test suite',
    shortcut = 't'
  })

  -- Language-specific items
  if project.language == 'rust' then
    table.insert(items, {
      id = 'check',
      label = 'Check (Fast)',
      icon = '✓',
      desc = 'Fast syntax check',
      shortcut = 'c'
    })

    table.insert(items, {
      id = 'clippy',
      label = 'Clippy',
      icon = '📎',
      desc = 'Linting with Clippy',
      shortcut = 'l'
    })

    table.insert(items, {
      id = 'fmt',
      label = 'Format Code',
      icon = '💅',
      desc = 'Run rustfmt',
      shortcut = 'f'
    })
  elseif project.language == 'go' then
    table.insert(items, {
      id = 'fmt',
      label = 'Format Code',
      icon = '💅',
      desc = 'Run gofmt',
      shortcut = 'f'
    })

    table.insert(items, {
      id = 'vet',
      label = 'Go Vet',
      icon = '🔍',
      desc = 'Static analysis',
      shortcut = 'v'
    })
  end

  -- Maintenance section
  table.insert(items, {
    id = 'separator_maint',
    label = 'Maintenance',
    is_separator = true
  })

  table.insert(items, {
    id = 'clean',
    label = 'Clean',
    icon = '🧹',
    desc = 'Remove build artifacts',
    shortcut = 'x'
  })

  if project.language == 'rust' then
    table.insert(items, {
      id = 'update',
      label = 'Update Dependencies',
      icon = '📦',
      desc = 'Cargo update',
      shortcut = 'u'
    })
  elseif project.language == 'go' then
    table.insert(items, {
      id = 'mod_tidy',
      label = 'Tidy Modules',
      icon = '📦',
      desc = 'go mod tidy',
      shortcut = 'u'
    })
  end

  -- Configuration section
  table.insert(items, {
    id = 'separator_config',
    label = 'Configuration',
    is_separator = true
  })

  if project.language == 'rust' then
    table.insert(items, {
      id = 'toggle_release',
      label = 'Toggle Profile',
      icon = '🎚️',
      desc = 'Switch dev/release',
      shortcut = 'p'
    })
  elseif project.language == 'cpp' then
    table.insert(items, {
      id = 'configure_cmake',
      label = 'CMake Configure',
      icon = '⚙️',
      desc = 'Generate build files',
      shortcut = 'g'
    })
  end

  return items
end

function M.handle_action(action_id, project)
  local executor = require('jason.executor')

  if action_id == 'build' then
    executor.build()
  elseif action_id == 'run' then
    executor.run()
  elseif action_id == 'build_run' then
    executor.build_and_run()
  elseif action_id == 'test' then
    executor.test()
  elseif action_id == 'clean' then
    executor.clean()
  elseif action_id == 'check' then
    executor.custom('cargo check')
  elseif action_id == 'clippy' then
    executor.custom('cargo clippy')
  elseif action_id == 'fmt' then
    if project.language == 'rust' then
      executor.custom('cargo fmt')
    elseif project.language == 'go' then
      executor.custom('gofmt -w .')
    end
  elseif action_id == 'vet' then
    executor.custom('go vet ./...')
  elseif action_id == 'update' then
    executor.custom('cargo update')
  elseif action_id == 'mod_tidy' then
    executor.custom('go mod tidy')
  elseif action_id == 'toggle_release' then
    M.toggle_rust_profile()
  elseif action_id == 'configure_cmake' then
    executor.custom('cmake -B build')
  end
end

function M.toggle_rust_profile()
  local config = require('jason').config
  local current = config.rust.profile
  config.rust.profile = current == 'dev' and 'release' or 'dev'
  vim.notify('Rust profile: ' .. config.rust.profile, vim.log.levels.INFO)
end

return M
