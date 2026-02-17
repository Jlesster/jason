# Polyglot Build Manager

A unified TUI build/run manager for multiple programming languages in Neovim.

## Features

- 🚀 **Unified Interface** - Same workflow across Java, Rust, Go, and C++
- 🎯 **Smart Detection** - Automatically detects project type and build system
- 🔨 **Multiple Build Systems** - Maven, Gradle, Cargo, Go modules, CMake, Make
- ⚡ **Single File Support** - Compile and run standalone files
- 🧪 **Testing** - Run tests across all languages
- 📦 **Error Parsing** - Jump to errors in quickfix list

## Supported Languages & Build Systems

### Java
- Maven (`pom.xml`)
- Gradle (`build.gradle`, `build.gradle.kts`)
- Single `.java` files with `javac`

### Rust
- Cargo (`Cargo.toml`)
- Single `.rs` files with `rustc`
- Profile switching (dev/release)
- Clippy and rustfmt integration

### Go
- Go modules (`go.mod`)
- Single `.go` files
- `go fmt` and `go vet` integration

### C/C++
- CMake (`CMakeLists.txt`)
- Make (`Makefile`)
- Single files with `g++`/`gcc`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/polyglot.nvim',
  config = function()
    require('polyglot').setup({
      keymaps = {
        dashboard = '<leader>pb',
        build = '<leader>pc',
        run = '<leader>pr',
        test = '<leader>pt',
        clean = '<leader>px',
      },
      terminal = {
        position = 'float', -- or 'split', 'vsplit', 'background'
        size = 0.4,
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/polyglot.nvim',
  config = function()
    require('polyglot').setup()
  end
}
```

## Usage

### Commands

- `:PolyDashboard` - Open the main dashboard
- `:PolyBuild` - Build the current project
- `:PolyRun` - Run the current project
- `:PolyTest` - Run tests
- `:PolyClean` - Clean build artifacts

### Default Keymaps

- `<leader>pb` - Open dashboard
- `<leader>pc` - Build
- `<leader>pr` - Run
- `<leader>pt` - Test
- `<leader>px` - Clean

### Dashboard Navigation

- `j`/`k` or `↑`/`↓` - Navigate
- `Enter` - Select action
- `q` or `Esc` - Close
- Shortcuts shown for quick access

## Configuration

### Full Configuration Example

```lua
require('polyglot').setup({
  ui_backend = 'auto', -- 'auto', 'snacks', 'dressing', 'builtin'
  
  terminal = {
    position = 'float', -- 'float', 'split', 'vsplit', 'background'
    size = 0.4,
    close_on_success = false,
  },
  
  quickfix = {
    auto_open = true,
    height = 10,
  },

  keymaps = {
    dashboard = '<leader>pb',
    build = '<leader>pc',
    run = '<leader>pr',
    test = '<leader>pt',
    clean = '<leader>px',
  },

  -- Language-specific
  java = {
    build_tool = 'auto', -- 'auto', 'maven', 'gradle', 'javac'
  },

  rust = {
    profile = 'dev', -- 'dev' or 'release'
  },

  cpp = {
    compiler = 'g++',
    standard = 'c++17',
  },
})
```

## Examples

### Java Project with Maven

```bash
cd my-maven-project
nvim src/main/java/Main.java
```

Press `<leader>pb` to open dashboard, then:
- `b` - Build with `mvn compile`
- `r` - Run with `mvn exec:java`
- `t` - Test with `mvn test`

### Rust Project with Cargo

```bash
cd my-rust-project
nvim src/main.rs
```

Dashboard actions:
- `b` - `cargo build`
- `r` - `cargo run`
- `c` - `cargo check` (fast)
- `l` - `cargo clippy`
- `f` - `cargo fmt`
- `p` - Toggle dev/release profile

### Go Project

```bash
cd my-go-project
nvim main.go
```

Dashboard actions:
- `b` - `go build .`
- `r` - `go run .`
- `t` - `go test ./...`
- `f` - `gofmt -w .`
- `v` - `go vet ./...`

### Single C++ File

```bash
nvim hello.cpp
```

Dashboard actions:
- `b` - Compile with `g++ -std=c++17`
- `r` - Run `./hello`

## Advanced Features

### Sequential Execution

The plugin supports build-then-run sequences. For example, "Build & Run" will:
1. Compile the project
2. Only run if compilation succeeds
3. Show both outputs

### Error Parsing

Errors are automatically parsed and added to quickfix:
- `:cnext` - Jump to next error
- `:cprev` - Jump to previous error
- `:copen` - Open quickfix window

### Profile Switching (Rust)

Toggle between dev and release profiles:
- Dev: Fast compilation, debug symbols
- Release: Optimized, slower compilation

Press `p` in the dashboard or use the toggle action.

## Integration with Marvin UI

If you're using the Marvin plugin, you can replace the simplified `ui.lua` with Marvin's full-featured UI module for:
- Fuzzy search in menus
- Better visual hierarchy
- Smooth animations
- Keyboard shortcuts overlay

Simply copy `marvin/ui.lua` to `polyglot/ui.lua`.

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## License

MIT

## Credits

Inspired by [Marvin](https://github.com/yourusername/marvin.nvim) - Maven manager for Neovim.
