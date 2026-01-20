# tiny-cloak.nvim Development Guide

## Build, Lint, and Test Commands

```bash
make test          # Run all tests (nvim headless)
make format        # Format Lua files with stylua
make lint          # Check formatting without changes
make install       # Install with LuaRocks
make dev-deps      # Install dev dependencies only
make clean         # Clean build artifacts
```

**Run single test:** Tests use a custom runner without individual test filtering. Run all tests to verify functionality:

```bash
nvim --headless -c "luafile test/runner.lua" -c "qall!"
```

**Via LuaRocks:**

```bash
luarocks test tiny-cloak.nvim-1.0.0-1.rockspec
```

## Code Style Guidelines

### File Structure

| Path                         | Purpose              |
| ---------------------------- | -------------------- |
| `lua/tiny-cloak/init.lua`    | Main plugin module   |
| `test/runner.lua`            | Test runner (custom) |
| `plugin/tiny-cloak.nvim.lua` | Plugin entry point   |
| `test.lua`                   | LuaRocks test entry  |
| `doc/tiny-cloak.nvim.txt`    | User documentation   |

### Formatting (StyLua)

```toml
column_width = 100
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "Always"
```

Run `stylua .` after changes.

### Naming Conventions

| Type           | Convention       | Example                         |
| -------------- | ---------------- | ------------------------------- |
| Module table   | `M`              | `local M = {}`                  |
| Functions/vars | snake_case       | `cloak_buffer`, `file_patterns` |
| Constants      | UPPER_SNAKE_CASE | `SENSITIVE_KEY_PATTERNS`        |
| Autocmd groups | PascalCase       | `TinyCloak`                     |
| Namespaces     | kebab-case       | `tiny-cloak`                    |
| Commands       | CamelCase        | `CloakToggle`                   |

### Imports & Dependencies

- Zero external dependencies
- Use `local M = require('tiny-cloak')`
- Use Neovim APIs: `vim.api.nvim_*`, `vim.fn.*`
- Always use `local` for variables

### Error Handling

```lua
function M.cloak_buffer(bufnr)
  if not enabled then return end
  if not bufnr then bufnr = vim.api.nvim_get_current_buf() end
  -- ... rest of function
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', default_config, opts)
end
```

### Buffer Handling

```lua
local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(bufnr, '/tmp/test.env')
vim.api.nvim_buf_set_option(bufnr, 'filetype', 'env')
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'content' })
vim.api.nvim_buf_delete(bufnr, { force = true })
```

### Testing Patterns

- Use `describe()` blocks with `test()` functions
- Custom `assert(condition, message)` function
- Buffer cleanup: `vim.api.nvim_buf_delete(bufnr, { force = true })`
- Tests run in headless Neovim (`os.exit(0)` pass, `1` fail)
- Create test buffers with `create_test_buffer({ name, filetype, lines })`

### Module Pattern

```lua
local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')
local enabled = true

local function helper() end

function M.setup(opts) end
function M.toggle() end

return M
```

### General Principles

- Minimal footprint, zero external dependencies
- Use Neovim native APIs (extmarks, autocmds, user commands)
- Keep functions focused and single-purpose
- Document public API in `doc/tiny-cloak.nvim.txt`

### Additional Context

See `CLAUDE.md` for collaboration guidelines.

## Configuration Options

| Option            | Type   | Default                                    | Description                 |
| ----------------- | ------ | ------------------------------------------ | --------------------------- |
| `file_patterns`   | table  | `{ '.env*', '*.json', '*.yaml', '*.yml' }` | File patterns to cloak      |
| `cloak_character` | string | `'*'`                                      | Character used for cloaking |
| `key_patterns`    | table  | API_KEY, SECRET, PASSWORD...               | Key patterns to detect      |

## Autocmd Patterns

```lua
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead' }, {
  group = 'TinyCloak',
  pattern = config.file_patterns,
  callback = function(args) M.cloak_buffer(args.buf) end,
})
```

## Extmark Usage

```lua
vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num, start_col, {
  end_col = end_col,
  virt_text = { { cloak_text, 'Comment' } },
  virt_text_pos = 'overlay',
})
```
