# tiny-cloak.nvim Development Guide

## Build, Lint, and Test Commands

```bash
make test          # Run all tests
make format        # Format Lua files (stylua)
make lint          # Check formatting without changes
make install       # Install with LuaRocks
make dev-deps      # Install dev dependencies
make clean         # Clean build artifacts
```

**Run single test:** Tests use a custom runner without individual test filtering. To test specific functionality, run all tests:
```bash
nvim --headless -c "luafile test/runner.lua" -c "qall!"
```

**Via LuaRocks:**
```bash
luarocks test tiny-cloak.nvim-1.0.0-1.rockspec
```

## Code Style Guidelines

### File Structure
- Main: `lua/tiny-cloak/init.lua`
- Tests: `test/runner.lua`
- Plugin entry: `plugin/tiny-cloak.nvim.lua`
- Test entry: `test.lua` (LuaRocks)

### Formatting (StyLua)
- Column width: 100
- Indent: 2 spaces
- Quote style: AutoPreferSingle
- Call parentheses: Always
- Run `stylua .` after changes

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Module table | `M` | `local M = {}` |
| Functions/vars | snake_case | `cloak_buffer`, `file_patterns` |
| Constants | UPPER_SNAKE_CASE | `SENSITIVE_KEY_PATTERNS` |
| Autocmd groups | PascalCase | `TinyCloak` |
| Namespaces | kebab-case | `tiny-cloak` |
| Commands | CamelCase | `CloakToggle` |

### Imports & Dependencies
- Use `local M = require('tiny-cloak')`
- Zero external dependencies
- Use Neovim APIs: `vim.api.nvim_*`, `vim.fn.*`
- Always use `local` for variables

### Error Handling
```lua
-- Guard clause pattern
function M.cloak_buffer(bufnr)
  if not enabled then return end
  -- ... rest of function
end

-- Config merging
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', default_config, opts)
end
```

### Module Pattern
```lua
local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')
local enabled = true

local function helper() end  -- Private helper

function M.setup(opts) end   -- Public API

return M
```

### Testing Patterns
- Use `describe()` blocks and `test()` functions
- Assertions: `assert(condition, message)`
- Clean up: `vim.api.nvim_buf_delete(bufnr, { force = true })`
- Tests run in Neovim headless mode
- Exit codes via `os.exit()` (0=pass, 1=fail)

### General Principles
- Minimal footprint, zero external dependencies
- Use Neovim native APIs (extmarks, autocmds, user commands)
- Keep functions focused and single-purpose
- Document public API in `doc/tiny-cloak.nvim.txt`
