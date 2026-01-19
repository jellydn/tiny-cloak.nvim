local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
  key_patterns = { 'API_KEY', 'SECRET', 'PASSWORD', 'TOKEN', 'CREDENTIAL', 'AUTH' },
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')
local enabled = true

local function matches_pattern(filename, patterns)
  for _, pattern in ipairs(patterns) do
    local regex_pattern = pattern:gsub('%.', '\\.'):gsub('%*', '.*')
    if vim.fn.match(filename, regex_pattern) ~= -1 then
      return true
    end
  end
  return false
end

local function cloak_env_value(line, bufnr, line_num)
  local key_patterns = M.config.key_patterns
  local key_end = nil

  for _, pattern in ipairs(key_patterns) do
    local start, end_ = string.find(line, '^' .. pattern)
    if start then
      key_end = end_
      break
    end
  end

  if key_end then
    local eq_pos = string.find(line, '=', key_end + 1)
    if eq_pos then
      local value_start = eq_pos + 1
      local value_length = #line - value_start + 1
      if value_length > 0 then
        M.cloak_line(bufnr, line_num, value_start - 1, value_start - 1 + value_length)
      end
    end
  end
end

function M.cloak_buffer(bufnr)
  if not enabled then
    return
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fs.basename(filepath)

  local config = M.config

  if not matches_pattern(filename, config.file_patterns) then
    return
  end

  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if filetype == 'env' or filename:match('^%.env') then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

    for i, line in ipairs(lines) do
      local trimmed = line:gsub('\r$', ''):gsub('\n$', '')
      if trimmed ~= '' and trimmed:sub(1, 1) ~= '#' then
        cloak_env_value(trimmed, bufnr, i - 1)
      end
    end
  end
end

function M.toggle()
  enabled = not enabled
  if not enabled then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
      end
    end
  else
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        M.cloak_buffer(bufnr)
      end
    end
  end
end

function M.enable()
  if not enabled then
    M.toggle()
  end
end

function M.disable()
  if enabled then
    M.toggle()
  end
end

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

  vim.api.nvim_create_augroup('TinyCloak', {})

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead' }, {
    group = 'TinyCloak',
    pattern = config.file_patterns,
    callback = function(args)
      M.cloak_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = 'TinyCloak',
    pattern = config.file_patterns,
    callback = function(args)
      M.cloak_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = 'TinyCloak',
    pattern = config.file_patterns,
    callback = function(args)
      M.cloak_buffer(args.buf)
    end,
  })

  vim.api.nvim_create_user_command('CloakToggle', M.toggle, {})
  vim.api.nvim_create_user_command('CloakEnable', M.enable, {})
  vim.api.nvim_create_user_command('CloakDisable', M.disable, {})
end

return M
