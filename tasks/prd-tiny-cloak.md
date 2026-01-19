# PRD: tiny-cloak.nvim

## Introduction

A lightweight Neovim plugin that masks sensitive data (API keys, secrets, tokens) in `.env`, JSON, and YAML files by overlaying them with `*` characters. The primary goal is security—preventing accidental exposure of credentials during screen sharing, demos, or pair programming sessions.

## Goals

- Automatically cloak sensitive values in `.env`, `.json`, `.yaml`, and `.yml` files
- Mask common secret patterns (API_KEY, SECRET, PASSWORD, TOKEN, etc.)
- Provide simple toggle commands for enabling/disabling cloaking
- Minimal footprint with no external dependencies
- Zero configuration required for common use cases

## User Stories

### US-001: Setup plugin structure
**Description:** As a developer, I need the basic plugin structure so the plugin can be loaded by Neovim package managers.

**Acceptance Criteria:**
- [x] `lua/tiny-cloak/init.lua` exports a `setup()` function
- [x] Plugin can be loaded via lazy.nvim, packer, or manual runtimepath
- [x] Default configuration is applied when `setup()` is called without arguments
- [x] Plugin loads without errors: `:lua require('tiny-cloak').setup()`

### US-002: Cloak .env files
**Description:** As a user, I want API keys in `.env` files automatically masked so I don't accidentally expose them.

**Acceptance Criteria:**
- [x] Values matching common patterns are cloaked: `API_KEY`, `SECRET`, `PASSWORD`, `TOKEN`, `CREDENTIAL`, `AUTH`
- [x] Only the value portion is cloaked (key name remains visible)
- [x] Cloak character is `*` by default
- [x] Example: `API_KEY=sk-abc123` displays as `API_KEY=**********`
- [x] Cloaking applies automatically when opening `.env` files

### US-003: Cloak JSON files
**Description:** As a user, I want secrets in JSON files masked so config files are safe to display.

**Acceptance Criteria:**
- [x] String values for keys matching common patterns are cloaked
- [x] Patterns: `api_key`, `apiKey`, `secret`, `password`, `token`, `credential`, `auth` (case-insensitive)
- [x] Example: `"apiKey": "sk-abc123"` displays as `"apiKey": "**********"`
- [x] Cloaking applies automatically when opening `.json` files

### US-004: Cloak YAML files
**Description:** As a user, I want secrets in YAML files masked so config files are safe to display.

**Acceptance Criteria:**
- [x] String values for keys matching common patterns are cloaked
- [x] Patterns: `api_key`, `apiKey`, `secret`, `password`, `token`, `credential`, `auth` (case-insensitive)
- [x] Example: `api_key: sk-abc123` displays as `api_key: **********`
- [x] Cloaking applies automatically when opening `.yaml` and `.yml` files

### US-005: Implement CloakToggle command
**Description:** As a user, I want to toggle cloaking on/off so I can temporarily view actual values.

**Acceptance Criteria:**
- [x] `:CloakToggle` command toggles cloaking state globally
- [x] When disabled, all cloaked values become visible
- [x] When re-enabled, values are cloaked again
- [x] State persists until toggled again or Neovim restarts

### US-006: Implement CloakEnable and CloakDisable commands
**Description:** As a user, I want explicit enable/disable commands for scripting and keymaps.

**Acceptance Criteria:**
- [x] `:CloakEnable` enables cloaking (no-op if already enabled)
- [x] `:CloakDisable` disables cloaking (no-op if already disabled)
- [x] Commands work from any buffer

### US-007: Configurable cloak character
**Description:** As a user, I want to customize the masking character to match my preferences.

**Acceptance Criteria:**
- [x] `setup({ cloak_character = "•" })` uses `•` instead of `*`
- [x] Single character only
- [x] Default remains `*`

### US-008: Configurable file patterns
**Description:** As a user, I want to add custom file patterns to cloak additional file types.

**Acceptance Criteria:**
- [x] `setup({ file_patterns = { ".env*", "*.json", "*.yaml", "*.yml" } })` configures patterns
- [x] Patterns use Neovim autocommand glob syntax
- [x] Default patterns cover `.env`, `.env.*`, `*.json`, `*.yaml`, `*.yml`

## Functional Requirements

- FR-1: Plugin must expose `require('tiny-cloak').setup(opts)` for initialization
- FR-2: Plugin must use Neovim's extmarks API for overlay text (not buffer modification)
- FR-3: Plugin must auto-attach to buffers matching configured file patterns via autocommands
- FR-4: Plugin must define `:CloakEnable`, `:CloakDisable`, and `:CloakToggle` user commands
- FR-5: Plugin must cloak values using Lua pattern matching for each file type
- FR-6: Plugin must preserve the original buffer content (read-only visual overlay only)
- FR-7: Plugin must re-apply cloaking when buffer content changes (on `TextChanged` events)

## Non-Goals

- No completion plugin integration (nvim-cmp, blink.cmp, etc.)
- No per-buffer toggle (global state only)
- No `:CloakPreviewLine` command (may add in future version)
- No highlight group customization in v1
- No support for custom regex patterns (Lua patterns only)

## Technical Considerations

- Use `vim.api.nvim_buf_set_extmark` with `virt_text` and `virt_text_pos = "overlay"` for cloaking
- Create a dedicated namespace via `vim.api.nvim_create_namespace("tiny-cloak")`
- Use `vim.api.nvim_create_autocmd` for BufEnter/BufRead events
- Pattern matching per file type:
  - `.env`: `^([A-Z_]*KEY[A-Z_]*|[A-Z_]*SECRET[A-Z_]*|[A-Z_]*PASSWORD[A-Z_]*|[A-Z_]*TOKEN[A-Z_]*|[A-Z_]*CREDENTIAL[A-Z_]*|[A-Z_]*AUTH[A-Z_]*)=(.+)$`
  - JSON: Match `"key": "value"` where key contains sensitive words
  - YAML: Match `key: value` where key contains sensitive words

## Success Metrics

- Plugin loads in < 5ms
- No visible flicker when opening cloaked files
- Zero false positives on common config files
- Works correctly with syntax highlighting enabled

## Design Decisions

- **Inline comments**: Do NOT cloak secrets in comments (only cloak actual key-value pairs)
- **Multiline strings**: Cloak line-by-line (each line of a multiline value is individually masked)
