# tiny-cloak.nvim

<p align="center">
  <img src="assets/logo.svg" alt="tiny-cloak logo" width="200" height="200"/>
</p>

[![License](https://img.shields.io/github/license/jellydn/tiny-cloak.nvim?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41)](https://github.com/jellydn/tiny-cloak.nvim/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/jellydn/tiny-cloak.nvim?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41)](https://github.com/jellydn/tiny-cloak.nvim/stargazers)
[![Issues](https://img.shields.io/github/issues/jellydn/tiny-cloak.nvim?style=for-the-badge&logo=bilibili&color=F5E0DC&logoColor=D9E0EE&labelColor=302D41)](https://github.com/jellydn/tiny-cloak.nvim/issues)

A lightweight Neovim plugin that masks sensitive data (API keys, secrets, tokens) in `.env`, JSON, and YAML files. Prevents accidental exposure of credentials during screen sharing, demos, or pair programming.

[![Demo](https://i.gyazo.com/0e0f1c253ad07f932b8f48deda54a7f0.gif)](https://gyazo.com/0e0f1c253ad07f932b8f48deda54a7f0)

## ✨ Features

- 🔒 Automatically cloak sensitive values in `.env`, `.json`, `.yaml`, and `.yml` files
- 🎯 Masks common patterns: `API_KEY`, `SECRET`, `PASSWORD`, `TOKEN`, `CREDENTIAL`, `AUTH`
- ⚡ Zero configuration required for common use cases
- 🪶 Minimal footprint with no external dependencies
- 👁️ Toggle commands to temporarily reveal values

## ⚡️ Requirements

- Neovim >= **0.8.0**

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jellydn/tiny-cloak.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "jellydn/tiny-cloak.nvim",
  config = function()
    require("tiny-cloak").setup()
  end,
}
```

## 🚀 Usage

The plugin works automatically once installed. Open any `.env`, `.json`, `.yaml`, or `.yml` file and sensitive values will be masked:

```env
# Before                          # After (displayed)
API_KEY=sk-example                API_KEY=***************
SECRET_TOKEN=example-secret       SECRET_TOKEN=************
```

## ⌨️ Commands

| Command               | Description                                  |
| --------------------- | -------------------------------------------- |
| `:CloakToggle`        | Toggle cloaking on/off globally              |
| `:CloakEnable`        | Enable cloaking (no-op if already enabled)   |
| `:CloakDisable`       | Disable cloaking (no-op if already disabled) |
| `:CloakPreviewToggle` | Toggle preview on current line               |

### Recommended Keymaps

```lua
-- Toggle cloaking globally
vim.keymap.set("n", "<leader>ct", "<cmd>CloakToggle<cr>", { desc = "Toggle cloak" })

-- Preview current line (toggle reveal/cloak)
vim.keymap.set("n", "<leader>cp", "<cmd>CloakPreviewToggle<cr>", { desc = "Preview line" })
```

## 👁️ Preview Feature

The plugin automatically reveals cloaked values when you enter insert mode for seamless editing:

- **Auto-reveal on Insert**: Enter insert mode on a cloaked line → value is revealed
- **Auto-recloak on Exit**: Press `Escape` → value is automatically re-cloaked
- **Manual Toggle**: `:CloakPreviewToggle` to reveal/hide in normal mode without editing

### Example Workflow

1. Navigate to a line with cloaked content
2. Press `i` to enter insert mode → value auto-reveals
3. Edit the value
4. Press `Escape` → value auto-recloaks

## ⚙️ Configuration

```lua
require("tiny-cloak").setup({
  -- Masking character
  cloak_character = "*", -- default

  -- File patterns to cloak
  file_patterns = { ".env*", "*.json", "*.yaml", "*.yml" }, -- default

  -- Key patterns to match for cloaking
  key_patterns = { "API_KEY", "SECRET", "PASSWORD", "TOKEN", "CREDENTIAL", "AUTH" }, -- default
})
```

## 🔧 How It Works

Uses Neovim's extmarks API to overlay text without modifying buffer content. Your files remain unchanged—only the visual display is masked.

## 📝 License

MIT
