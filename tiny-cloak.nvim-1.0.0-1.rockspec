rockspec_format = "3.0"
package = "tiny-cloak.nvim"
version = "1.0.0-1"
description = {
  summary = "A minimal Neovim plugin to hide sensitive information in config files",
  detailed = [[
    tiny-cloak.nvim is a minimal Neovim plugin that automatically hides sensitive
    information like API keys, passwords, and tokens in configuration files.
    Supports .env, JSON, YAML, and YML file formats.
  ]],
  license = "MIT",
  homepage = "https://github.com/jellydn/tiny-cloak.nvim",
  issues_url = "https://github.com/jellydn/tiny-cloak.nvim/issues",
}
dependencies = {
  "lua >= 5.1",
}
source = {
  url = "git+https://github.com/jellydn/tiny-cloak.nvim",
  tag = "v1.0.0",
}
build = {
  type = "builtin",
  modules = {
    ["tiny-cloak"] = "lua/tiny-cloak/init.lua",
  },
  copy_directories = {
    "plugin",
    "doc",
  },
}
test_dependencies = {
  "nlua",
}
test = {
  type = "command",
  test = { "nvim", "--headless", "-c", "luafile test/runner.lua" },
}
