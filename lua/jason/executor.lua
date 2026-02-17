-- lua/jason/executor.lua
local M = {}

M.current_job = nil

-- Build command builders for each project type
local builders = {
  maven = {
    build = 'mvn compile',
    run = function(project)
      return 'mvn exec:java -Dexec.mainClass=' .. M.find_main_class(project)
    end,
    test = 'mvn test',
    clean = 'mvn clean',
  },

  gradle = {
    build = './gradlew build',
    run = './gradlew run',
    test = './gradlew test',
    clean = './gradlew clean',
  },

  cargo = {
    build = function(project)
      local config = require('jason').config
      local profile = config.rust.profile
      return profile == 'release' and 'cargo build --release' or 'cargo build'
    end,
    run = function(project)
      local config = require('jason').config
      local profile = config.rust.profile
      return profile == 'release' and 'cargo run --release' or 'cargo run'
    end,
    test = 'cargo test',
    clean = 'cargo clean',
  },

  go_mod = {
    build = 'go build .',
    run = 'go run .',
    test = 'go test ./...',
    clean = 'go clean',
  },

  cmake = {
    build = 'cmake --build build',
    run = function(project)
      -- Find executable in build directory
      local exe = M.find_cmake_executable(project)
      return exe or './build/main'
    end,
    test = 'ctest --test-dir build',
    clean = 'rm -rf build',
  },

  makefile = {
    build = 'make',
    run = function(project)
      local exe = M.find_makefile_executable(project)
      return exe or './main'
    end,
    test = 'make test',
    clean = 'make clean',
  },

  single_file = {
    build = function(project)
      local ft = project.language
      local file = project.file
      local base = vim.fn.fnamemodify(file, ':t:r')

      if ft == 'java' then
        return 'javac ' .. file
      elseif ft == 'rust' then
        return 'rustc ' .. file
      elseif ft == 'go' then
        return 'go build ' .. file
      elseif ft == 'cpp' then
        local config = require('jason').config
        return string.format('%s -std=%s %s -o %s',
          config.cpp.compiler, config.cpp.standard, file, base)
      elseif ft == 'c' then
        return 'gcc ' .. file .. ' -o ' .. base
      end
    end,
    run = function(project)
      local ft = project.language
      local file = project.file
      local base = vim.fn.fnamemodify(file, ':t:r')

      if ft == 'java' then
        return 'java ' .. base
      elseif ft == 'rust' then
        return './' .. base
      elseif ft == 'go' then
        return 'go run ' .. file
      elseif ft == 'cpp' or ft == 'c' then
        return './' .. base
      end
    end,
    test = nil,
    clean = function(project)
      local base = vim.fn.fnamemodify(project.file, ':t:r')
      return 'rm -f ' .. base
    end,
  },
}

function M.build()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  if not detector.validate_environment(project.type) then
    return
  end

  local cmd = M.get_command('build', project)
  if not cmd then
    vim.notify('Build not supported for ' .. project.type, vim.log.levels.WARN)
    return
  end

  M.execute(cmd, project.root, 'Build')
end

function M.run()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  local cmd = M.get_command('run', project)
  if not cmd then
    vim.notify('Run not supported for ' .. project.type, vim.log.levels.WARN)
    return
  end

  M.execute(cmd, project.root, 'Run')
end

function M.build_and_run()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  local build_cmd = M.get_command('build', project)
  local run_cmd = M.get_command('run', project)

  if not build_cmd or not run_cmd then
    vim.notify('Build & Run not fully supported', vim.log.levels.WARN)
    return
  end

  -- Execute build first, then run on success
  M.execute_sequence({
    { cmd = build_cmd, title = 'Build' },
    { cmd = run_cmd,   title = 'Run' },
  }, project.root)
end

function M.test()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  local cmd = M.get_command('test', project)
  if not cmd then
    vim.notify('Tests not supported for ' .. project.type, vim.log.levels.WARN)
    return
  end

  M.execute(cmd, project.root, 'Test')
end

function M.clean()
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  local cmd = M.get_command('clean', project)
  if not cmd then
    vim.notify('Clean not supported for ' .. project.type, vim.log.levels.WARN)
    return
  end

  M.execute(cmd, project.root, 'Clean')
end

function M.custom(cmd)
  local detector = require('jason.detector')
  local project = detector.get_project()

  if not project then
    vim.notify('No project detected', vim.log.levels.ERROR)
    return
  end

  M.execute(cmd, project.root, 'Custom')
end

function M.get_command(action, project)
  local builder = builders[project.type]
  if not builder then return nil end

  local cmd = builder[action]
  if type(cmd) == 'function' then
    return cmd(project)
  end
  return cmd
end

function M.execute(cmd, cwd, title)
  local config = require('jason').config

  if config.terminal.position == 'background' then
    M.run_background(cmd, cwd, title)
  else
    M.run_terminal(cmd, cwd, title)
  end
end

function M.execute_sequence(commands, cwd)
  local idx = 1

  local function run_next()
    if idx > #commands then
      vim.notify('✅ All tasks completed!', vim.log.levels.INFO)
      return
    end

    local task = commands[idx]

    vim.notify('🔨 ' .. task.title .. '...', vim.log.levels.INFO)

    M.current_job = vim.fn.jobstart(task.cmd, {
      cwd = cwd,
      stdout_buffered = true,
      stderr_buffered = true,
      on_exit = function(_, exit_code, _)
        M.current_job = nil

        if exit_code == 0 then
          idx = idx + 1
          vim.schedule(run_next)
        else
          vim.notify('❌ ' .. task.title .. ' failed!', vim.log.levels.ERROR)
        end
      end,
    })
  end

  run_next()
end

function M.run_background(cmd, cwd, title)
  local output = {}

  vim.notify('🔨 ' .. title .. ': ' .. cmd, vim.log.levels.INFO)

  M.current_job = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_stderr = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_exit = function(_, exit_code, _)
      M.current_job = nil

      if exit_code == 0 then
        vim.notify('✅ ' .. title .. ' successful!', vim.log.levels.INFO)
      else
        vim.notify('❌ ' .. title .. ' failed!', vim.log.levels.ERROR)

        local parser = require('jason.parser')
        parser.parse_output(output)
      end
    end,
  })
end

function M.run_terminal(cmd, cwd, title)
  local config = require('jason').config
  local term_config = config.terminal

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local win
  if term_config.position == 'split' then
    vim.cmd('split')
    win = vim.api.nvim_get_current_win()
    local height = math.floor(vim.api.nvim_win_get_height(win) * term_config.size)
    vim.api.nvim_win_set_height(win, height)
    vim.api.nvim_win_set_buf(win, buf)
  elseif term_config.position == 'vsplit' then
    vim.cmd('vsplit')
    win = vim.api.nvim_get_current_win()
    local width = math.floor(vim.api.nvim_win_get_width(win) * term_config.size)
    vim.api.nvim_win_set_width(win, width)
    vim.api.nvim_win_set_buf(win, buf)
  else
    -- Float window
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * 0.8)
    local height = math.floor(ui.height * term_config.size)
    local row = math.floor((ui.height - height) / 2)
    local col = math.floor((ui.width - width) / 2)

    win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      title = ' ' .. title .. ' ',
      title_pos = 'center',
    })
  end

  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)

  local output = {}
  M.current_job = vim.fn.termopen(cmd, {
    cwd = cwd,
    on_stdout = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_stderr = function(_, data, _)
      vim.list_extend(output, data)
    end,
    on_exit = function(_, exit_code, _)
      M.current_job = nil

      if exit_code == 0 then
        if term_config.close_on_success then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 1000)
        end
        vim.notify('✅ ' .. title .. ' successful!', vim.log.levels.INFO)
      else
        vim.notify('❌ ' .. title .. ' failed!', vim.log.levels.ERROR)

        local parser = require('jason.parser')
        parser.parse_output(output)
      end
    end,
  })

  vim.cmd('startinsert')

  local opts = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, opts)

  vim.keymap.set('t', '<Esc><Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, opts)
end

-- Helper functions
function M.find_main_class(project)
  -- Search for main method in Java files
  local java_files = vim.fn.globpath(project.root .. '/src/main/java', '**/*.java', false, true)

  for _, file in ipairs(java_files) do
    local lines = vim.fn.readfile(file)
    local package_name, class_name, has_main = nil, nil, false

    for _, line in ipairs(lines) do
      if line:match('^%s*package%s+') then
        package_name = line:match('package%s+([%w%.]+)')
      end
      if line:match('public%s+class%s+') then
        class_name = line:match('class%s+(%w+)')
      end
      if line:match('public%s+static%s+void%s+main') then
        has_main = true
      end

      if package_name and class_name and has_main then
        return package_name .. '.' .. class_name
      end
    end
  end

  return 'Main'
end

function M.find_cmake_executable(project)
  local build_dir = project.root .. '/build'
  if vim.fn.isdirectory(build_dir) == 0 then
    return nil
  end

  -- Look for executables (files with execute permission)
  local handle = io.popen('find "' .. build_dir .. '" -type f -executable 2>/dev/null | head -1')
  if handle then
    local exe = handle:read('*l')
    handle:close()
    return exe
  end

  return nil
end

function M.find_makefile_executable(project)
  -- Try common executable names
  local common_names = { 'main', 'app', 'program', 'a.out' }

  for _, name in ipairs(common_names) do
    local path = project.root .. '/' .. name
    if vim.fn.executable(path) == 1 then
      return './' .. name
    end
  end

  return nil
end

function M.stop()
  if M.current_job then
    vim.fn.jobstop(M.current_job)
    M.current_job = nil
    vim.notify('Task stopped', vim.log.levels.WARN)
  end
end

return M
