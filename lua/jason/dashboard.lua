-- lua/jason/dashboard.lua
local M = {}

M.run_history = {}
M.max_history = 20

local function add_history(entry)
  entry.timestamp = os.time()
  table.insert(M.run_history, 1, entry)
  if #M.run_history > M.max_history then
    table.remove(M.run_history)
  end
end

local function ago(ts)
  local d = os.time() - ts
  if d < 60 then
    return 'just now'
  elseif d < 3600 then
    return math.floor(d / 60) .. 'm ago'
  elseif d < 86400 then
    return math.floor(d / 3600) .. 'h ago'
  else
    return math.floor(d / 86400) .. 'd ago'
  end
end

local function sep(label)
  return { id = 'sep_' .. label, label = label, is_separator = true }
end

local function item(id, icon, label, desc, badge)
  return { id = id, icon = icon, label = label, desc = desc, badge = badge }
end

-- ── Build the menu for a given project ───────────────────────────────────────
function M.build_menu(project, status)
  local ex    = require('jason.executor')
  local cfg   = require('jason').config
  local lang  = project.language
  local ptype = project.type
  local items = {}

  local function add(t) items[#items + 1] = t end

  -- ── Core actions ───────────────────────────────────────────────────────────
  add(sep('Run'))
  add(item('build_run', '▶', 'Build & Run', 'Compile then execute'))
  add(item('test', '󰙨', 'Test', 'Run test suite'))
  add(item('run', '󰐊', 'Run Only', 'Execute last build'))

  add(sep('Build'))
  add(item('build', '󰔷', 'Build', 'Compile sources'))
  add(item('clean_build', '󰑕', 'Clean & Build', 'Wipe then compile'))
  add(item('clean', '󰃢', 'Clean', 'Remove build artifacts'))

  -- ── Language tools ─────────────────────────────────────────────────────────
  if lang == 'rust' then
    add(sep('Rust'))
    add(item('check', '󰄬', 'Check', 'Type-check without codegen'))
    add(item('clippy', '󰁨', 'Clippy', 'Lints and suggestions'))
    add(item('fmt', '󰉣', 'Format', 'Run rustfmt'))
    add(item('doc', '󰈙', 'Docs', 'cargo doc --open'))
    add(item('bench', '󰦉', 'Bench', 'Run benchmarks'))

    add(sep('Profile'))
    local cur = cfg.rust.profile
    local nxt = cur == 'release' and 'dev' or 'release'
    add(item('toggle_profile', '󰒓', 'Profile: ' .. cur, 'Switch to ' .. nxt,
      cur == 'release' and '󰓅 release' or '󰁌 dev'))
  elseif lang == 'go' then
    add(sep('Go'))
    add(item('fmt', '󰉣', 'Format', 'gofmt -w .'))
    add(item('vet', '󰁨', 'Vet', 'go vet ./...'))
    add(item('lint', '󰁨', 'Lint', 'golangci-lint run'))
    add(item('coverage', '󰦉', 'Coverage', 'go test -cover ./...'))
  elseif lang == 'java' then
    add(sep('Java'))
    if ptype == 'maven' then
      add(item('dependency_tree', '󰙅', 'Dep Tree', 'mvn dependency:tree'))
      add(item('effective_pom', '󰈙', 'Effective POM', 'mvn help:effective-pom'))
      add(item('verify', '󰄬', 'Verify', 'Run integration tests'))
    elseif ptype == 'gradle' then
      add(item('dependencies', '󰙅', 'Dependencies', './gradlew dependencies'))
      add(item('tasks', '󰒓', 'Tasks', './gradlew tasks'))
    end

    -- GraalVM section (shown whenever language is java, grayed badge when unavailable)
    local graal    = require('jason.graalvm')
    local has_ni   = graal.native_image_bin() ~= nil
    local ni_badge = has_ni and '●' or '○ needs install'
    add(sep('GraalVM'))
    add(item('graal_build_native', 'ó°¡', 'Build Native', 'Compile to native binary', ni_badge))
    add(item('graal_run_native', '▶', 'Run Native', 'Execute native binary'))
    add(item('graal_build_run', 'ó°"·', 'Build & Run', 'Native build then run'))
    add(item('graal_agent_run', 'ó°ˆ™', 'Agent Run', 'Collect reflection config'))
    add(item('graal_info', 'ó°†', 'GraalVM Info', 'Show status & config'))
    if not has_ni then
      add(item('graal_install_ni', 'ó°š°', 'Install native-image', 'Run: gu install native-image'))
    end
  elseif lang == 'cpp' then
    add(sep('C++'))
    add(item('clang_format', '󰉣', 'Format', 'clang-format -i'))
    add(item('clang_tidy', '󰁨', 'Tidy', 'clang-tidy checks'))
    if ptype == 'cmake' then
      add(item('configure_cmake', '󰒓', 'Configure', 'cmake -B build'))
    end
  end

  -- ── Dependencies ───────────────────────────────────────────────────────────
  add(sep('Dependencies'))
  if lang == 'rust' then
    add(item('update', '󰚰', 'Update', 'cargo update'))
    add(item('outdated', '󰦉', 'Outdated', 'cargo outdated'))
    add(item('audit', '󰒃', 'Audit', 'cargo audit'))
  elseif lang == 'go' then
    add(item('mod_tidy', '󰚰', 'Tidy', 'go mod tidy'))
    add(item('mod_download', '󰚰', 'Download', 'go mod download'))
    add(item('mod_verify', '󰄬', 'Verify', 'go mod verify'))
  elseif lang == 'java' and ptype == 'maven' then
    add(item('update', '󰚰', 'Check Updates', 'mvn versions:display-dependency-updates'))
    add(item('purge', '󰃢', 'Purge Cache', 'mvn dependency:purge-local-repository'))
  end

  -- ── Settings ───────────────────────────────────────────────────────────────
  add(sep('Settings'))
  add(item('terminal_settings', '󰆍', 'Terminal',
    'Position: ' .. cfg.terminal.position))
  add(item('keybindings', '󰌌', 'Keybindings', 'View all shortcuts'))

  -- ── History ────────────────────────────────────────────────────────────────
  if #M.run_history > 0 then
    add(sep('History'))
    add(item('show_history', '󰋚', 'History',
      #M.run_history .. ' recent runs'))
    local last = M.run_history[1]
    if last then
      local si = last.success and '✓' or last.success == false and '✗' or '…'
      add(item('rerun_last', '󰑕', 'Rerun Last',
        last.action .. ' · ' .. ago(last.timestamp), si))
    end
  end

  return items
end

-- ── Show dashboard ────────────────────────────────────────────────────────────
function M.show()
  local detector = require('jason.detector')
  local project  = detector.get_project()
  if not project then
    vim.notify('No project detected', vim.log.levels.WARN)
    return
  end

  local status = { branch = 'main', dirty = false }
  local branch = vim.trim(vim.fn.system(
    'git -C ' .. vim.fn.shellescape(project.root) .. ' branch --show-current 2>/dev/null'))
  if branch ~= '' then
    status.branch = branch
    local st = vim.fn.system(
      'git -C ' .. vim.fn.shellescape(project.root) .. ' status --porcelain 2>/dev/null')
    status.dirty = vim.trim(st) ~= ''
  end

  local menu  = M.build_menu(project, status)
  local ui    = require('jason.ui')
  local pname = vim.fn.fnamemodify(project.root, ':t')
  local dirty = status.dirty and ' ●' or ''

  ui.select(menu, {
    prompt        = pname .. ' [' .. project.language:upper() .. ']' .. dirty,
    project       = project,
    show_preview  = true,
    enable_search = true,
    format_item   = function(it)
      if it.is_separator then return it.label end
      return (it.icon and it.icon .. ' ' or '') .. it.label
    end,
  }, function(choice)
    if choice then M.handle_action(choice.id, project) end
  end)
end

-- ── Action handler ────────────────────────────────────────────────────────────
function M.handle_action(id, project)
  local ex  = require('jason.executor')
  local cfg = require('jason').config

  local function run(action, cmd_fn)
    local start = os.time()
    cmd_fn()
    add_history({
      action    = action,
      action_id = id,
      project   = project.language,
      success   = nil,
      duration  = os.time() - start,
    })
  end

  if id == 'build' then
    run('Build', function() ex.build() end)
  elseif id == 'run' then
    run('Run', function() ex.run() end)
  elseif id == 'build_run' then
    run('Build & Run', function() ex.build_and_run() end)
  elseif id == 'test' then
    run('Test', function() ex.test() end)
  elseif id == 'clean' then
    run('Clean', function() ex.clean() end)
  elseif id == 'clean_build' then
    run('Clean & Build', function()
      ex.execute_sequence({
        { cmd = ex.get_command('clean', project), title = 'Clean' },
        { cmd = ex.get_command('build', project), title = 'Build' },
      }, project.root)
    end)

    -- Rust
  elseif id == 'check' then
    run('Check', function() ex.custom('cargo check') end)
  elseif id == 'clippy' then
    run('Clippy', function() ex.custom('cargo clippy') end)
  elseif id == 'fmt' then
    local cmd = project.language == 'rust' and 'cargo fmt'
        or project.language == 'go' and 'gofmt -w .'
        or 'clang-format -i $(find . -name "*.cpp" -o -name "*.h" | head -20)'
    run('Format', function() ex.custom(cmd) end)
  elseif id == 'doc' then
    run('Docs', function() ex.custom('cargo doc --open') end)
  elseif id == 'bench' then
    run('Bench', function() ex.custom('cargo bench') end)
  elseif id == 'toggle_profile' then
    cfg.rust.profile = cfg.rust.profile == 'release' and 'dev' or 'release'
    vim.notify('Rust profile: ' .. cfg.rust.profile, vim.log.levels.INFO)
    vim.defer_fn(function() M.show() end, 50)
    return

    -- Go
  elseif id == 'vet' then
    run('Vet', function() ex.custom('go vet ./...') end)
  elseif id == 'lint' then
    run('Lint', function() ex.custom('golangci-lint run') end)
  elseif id == 'coverage' then
    run('Coverage', function() ex.custom('go test -cover ./...') end)
  elseif id == 'mod_tidy' then
    run('Tidy', function() ex.custom('go mod tidy') end)
  elseif id == 'mod_download' then
    run('Download', function() ex.custom('go mod download') end)
  elseif id == 'mod_verify' then
    run('Verify', function() ex.custom('go mod verify') end)

    -- Java
  elseif id == 'graal_build_native' then
    run('Native Build', function()
      require('jason.graalvm').build_native(project)
    end)
  elseif id == 'graal_run_native' then
    run('Run Native', function()
      require('jason.graalvm').run_native(project)
    end)
  elseif id == 'graal_build_run' then
    run('Native Build & Run', function()
      require('jason.graalvm').build_and_run_native(project)
    end)
  elseif id == 'graal_agent_run' then
    run('Agent Run', function()
      require('jason.graalvm').run_with_agent(project)
    end)
  elseif id == 'graal_info' then
    require('jason.graalvm').show_info()
    return -- no history entry needed
  elseif id == 'graal_install_ni' then
    run('Install native-image', function()
      require('jason.graalvm').install_native_image(project)
    end)
  elseif id == 'dependency_tree' then
    run('Dep Tree', function() ex.custom('mvn dependency:tree') end)
  elseif id == 'effective_pom' then
    run('Eff POM', function() ex.custom('mvn help:effective-pom') end)
  elseif id == 'verify' then
    run('Verify', function() ex.custom('mvn verify') end)
  elseif id == 'dependencies' then
    run('Deps', function() ex.custom('./gradlew dependencies') end)
  elseif id == 'tasks' then
    run('Tasks', function() ex.custom('./gradlew tasks') end)
  elseif id == 'update' then
    local cmd = project.language == 'rust' and 'cargo update'
        or project.language == 'java' and 'mvn versions:display-dependency-updates'
        or 'go get -u ./...'
    run('Update', function() ex.custom(cmd) end)
  elseif id == 'outdated' then
    run('Outdated', function() ex.custom('cargo outdated') end)
  elseif id == 'audit' then
    run('Audit', function() ex.custom('cargo audit') end)
  elseif id == 'purge' then
    run('Purge', function() ex.custom('mvn dependency:purge-local-repository') end)

    -- C++
  elseif id == 'clang_format' then
    run('Format', function() ex.custom('find . -name "*.cpp" -o -name "*.h" | xargs clang-format -i') end)
  elseif id == 'clang_tidy' then
    run('Tidy', function() ex.custom('clang-tidy src/*.cpp') end)
  elseif id == 'configure_cmake' then
    run('CMake Cfg', function() ex.custom('cmake -B build') end)

    -- Settings
  elseif id == 'terminal_settings' then
    M.show_terminal_settings()
  elseif id == 'keybindings' then
    M.show_keybindings()
  elseif id == 'show_history' then
    M.show_history()
  elseif id == 'rerun_last' then
    if M.run_history[1] then
      M.handle_action(M.run_history[1].action_id, project)
    end
  end
end

-- ── Sub-menus ─────────────────────────────────────────────────────────────────
function M.show_terminal_settings()
  local ui  = require('jason.ui')
  local cfg = require('jason').config
  ui.select({
    { id = 'float',      label = 'Float',      desc = 'Centered overlay window' },
    { id = 'split',      label = 'Split',      desc = 'Horizontal split below' },
    { id = 'vsplit',     label = 'Vsplit',     desc = 'Vertical split beside' },
    { id = 'background', label = 'Background', desc = 'Silent, notify on done' },
  }, {
    prompt = 'Terminal Position',
    format_item = function(it) return it.label end,
  }, function(choice)
    if choice then
      cfg.terminal.position = choice.id
      vim.notify('Terminal: ' .. choice.id, vim.log.levels.INFO)
    end
  end)
end

function M.show_keybindings()
  local cfg = require('jason').config.keymaps
  local lines = {
    '',
    '  Jason Keybindings',
    '  ' .. string.rep('─', 30),
    '',
    string.format('  %-18s %s', cfg.dashboard or '<leader>jb', 'Open dashboard'),
    string.format('  %-18s %s', cfg.build or '<leader>jc', 'Build'),
    string.format('  %-18s %s', cfg.run or '<leader>jr', 'Run'),
    string.format('  %-18s %s', cfg.test or '<leader>jt', 'Test'),
    string.format('  %-18s %s', cfg.clean or '<leader>jx', 'Clean'),
    '',
    '  In the menu: j/k  navigate · ⏎ select · ⎋ quit',
    '               type to fuzzy-search',
    '',
  }
  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, true, {})
end

function M.show_history()
  if #M.run_history == 0 then
    vim.notify('No history yet', vim.log.levels.INFO); return
  end
  local ui    = require('jason.ui')
  local items = {}
  for _, e in ipairs(M.run_history) do
    local si = e.success and '✓' or e.success == false and '✗' or '…'
    items[#items + 1] = {
      id     = e.action_id,
      label  = e.action,
      desc   = e.project .. ' · ' .. ago(e.timestamp),
      badge  = si,
      _entry = e,
    }
  end
  ui.select(items, {
    prompt = 'Run History',
    format_item = function(it) return it.label end,
    enable_search = true,
  }, function(choice)
    if choice then
      M.handle_action(choice.id, require('jason.detector').get_project())
    end
  end)
end

return M
