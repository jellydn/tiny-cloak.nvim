local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')

function M.cloak_line(bufnr, line_num, start_col, end_col)
  local config = M.config
  local line_length = end_col - start_col
  local cloak_char = config.cloak_character
  local cloak_text = string.rep(cloak_char, line_length)

  vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num, start_col, {
    end_col = end_col,
    virt_text = { { cloak_text, 'Comment' } },
    virt_text_pos = 'overlay',
  })
end

function M.setup(opts)
  opts = opts or {}
  local config = vim.tbl_deep_extend('force', default_config, opts)
  M.config = config
end

return M
