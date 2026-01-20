-- Project-specific Neovim configuration

-- Set TypeScript LSP server
vim.g.lsp_typescript_server = "ts_ls" -- or "vtsls"

-- Enable additional LSP servers
vim.g.lsp_on_demands = {
}

-- Enable extra plugins
vim.g.enable_extra_plugins = {
    "cloak",
}

-- Add any other project-specific settings below
-- vim.opt.tabstop = 2
-- vim.opt.shiftwidth = 2
