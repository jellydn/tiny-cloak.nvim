# AGENTS.md - tiny-cloak.nvim Development Guide

This document provides guidelines for agentic coding agents working on tiny-cloak.nvim.

## Project Overview

tiny-cloak.nvim is a lightweight Neovim plugin that masks sensitive data (API keys, secrets, tokens) in `.env`, JSON, and YAML files. The plugin uses Neovim's extmarks API to overlay text without modifying buffer content.

## Build, Lint, and Test Commands

### Makefile Commands

```bash
make test        # Run all tests
make test-file   # Run test file
make format      # Format Lua files
make lint        # Check formatting
make install     # Install with LuaRocks
make dev-deps    # Install development dependencies
make clean       # Clean build artifacts
make help        # Show this help
```

### Running Tests

```bash
# Run all tests (uses Neovim headless)
nvim --headless -c "luafile test/runner.lua" -c "qall!"

# Tests use a custom runner at test/runner.lua
# It creates real Neovim buffers and verifies extmarks
```

### Code Formatting

```bash
# Format all Lua files with StyLua
stylua lua/
stylua test/

# Check formatting without applying changes
stylua --check lua/
```

### LuaRocks Package Management

```bash
# Install dependencies
luarocks install --deps-only tiny-cloak.nvim-1.0.0-1.rockspec

# Install with test dependencies
luarocks install tiny-cloak.nvim-1.0.0-1.rockspec

# Run tests via LuaRocks (uses shell test type with nvim)
luarocks test tiny-cloak.nvim-1.0.0-1.rockspec
```

## Code Style Guidelines

### File Structure

- Main module: `lua/tiny-cloak/init.lua`
- Tests: `test/plugin_spec.lua`
- Plugin entry: `plugin/tiny-cloak.nvim.lua`
- Documentation: `doc/tiny-cloak.nvim.txt`

### Formatting (StyLua Configuration)

- **Column width**: 100 characters
- **Line endings**: Unix
- **Indent type**: Spaces (2 spaces)
- **Quote style**: AutoPreferSingle
- **Call parentheses**: Always

Always run `stylua` after writing Lua code.

### Naming Conventions

- **Module**: `tiny-cloak` (kebab-case for directory names)
- **Module table**: `M` (exported module at bottom of file)
- **Functions**: snake_case (e.g., `cloak_buffer`, `trim_line`)
- **Variables**: snake_case (e.g., `file_patterns`, `key_end`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `SENSITIVE_KEY_PATTERNS`)
- **Autocmd groups**: PascalCase (e.g., `TinyCloak`)
- **Namespaces**: kebab-case with dots (e.g., `vim.api.nvim_create_namespace('tiny-cloak')`)
- **Commands**: CamelCase (e.g., `CloakToggle`, `CloakEnable`)

### Imports and Dependencies

- Use `local M = require('tiny-cloak')` to import the main module
- No external Lua dependencies (zero external dependencies)
- Use Neovim APIs via `vim.api.nvim_*` and `vim.fn.*`
- Avoid global namespace pollution; always use `local` for variables

### Types and Type Annotations

- Lua is dynamically typed; no type annotations required
- Use clear, descriptive variable names to convey intent
- For complex data structures, define default configs at module level

### Error Handling

- Use guard clauses for early returns on invalid input
- `if not condition then return end` pattern for preconditions
- Let Neovim API errors propagate (e.g., invalid bufnr)
- No exceptions; use return values and nil checks

### Code Patterns

**Module structure:**
```lua
local M = {}

local default_config = { -- private config
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')
local enabled = true

-- Private helper functions (local)
local function helper() end

-- Public API (M.function_name)
function M.setup(opts) end

return M
```

**Guard clause pattern:**
```lua
function M.cloak_buffer(bufnr)
  if not enabled then
    return
  end
  -- ... rest of function
end
```

**Config merging pattern:**
```lua
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', default_config, opts)
end
```

**Autocmd setup pattern:**
```lua
vim.api.nvim_create_augroup('TinyCloak', {})

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead' }, {
  group = 'TinyCloak',
  pattern = config.file_patterns,
  callback = function(args)
    M.cloak_buffer(args.buf)
  end,
})
```

### Testing Patterns (custom runner)

- Use `describe` blocks for grouping related tests
- Use `test()` function for individual test cases
- Assertions use `assert(condition, message)` function
- Clean up test buffers with `vim.api.nvim_buf_delete(bufnr, { force = true })`
- Tests run in Neovim headless mode with real buffers
- Always create a fresh buffer for each test
- Tests use `os.exit()` for proper exit codes
- The `.busted` file configures nlua as the Lua interpreter

### Documentation

- Document public API in `doc/tiny-cloak.nvim.txt` using Neovim help tags
- Add `:help tiny-cloak` entries for commands and configuration options
- Keep README.md updated with features and usage examples

### General Principles

- Minimal footprint with no external dependencies
- Zero configuration required for common use cases
- Use Neovim native APIs (extmarks, autocmds, user commands)
- Keep functions focused and single-purpose
- Avoid unnecessary abstraction; prefer simple, readable code
