local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
}

function M.setup(opts)
  opts = opts or {}
  local config = vim.tbl_deep_extend('force', default_config, opts)
  M.config = config
end

return M
