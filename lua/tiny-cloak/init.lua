local M = {}

local default_config = {
  file_patterns = { '.env*', '*.json', '*.yaml', '*.yml' },
  cloak_character = '*',
  key_patterns = { 'API_KEY', 'SECRET', 'PASSWORD', 'TOKEN', 'CREDENTIAL', 'AUTH' },
}

local namespace = vim.api.nvim_create_namespace('tiny-cloak')
local enabled = true

-- Preview state tracking
local preview_active_bufnr = nil
local preview_line_num = nil
local preview_extmarks = {}
local preview_autocmd_id = nil

-- Shared patterns for JSON/YAML sensitive keys
local SENSITIVE_KEY_PATTERNS = {
  'api_key',
  'apiKey',
  'secret',
  'password',
  'token',
  'credential',
  'auth',
}

local function trim_line(line)
  return line:gsub('[\r\n]$', '')
end

local function iter_loaded_buffers(fn)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      fn(bufnr)
    end
  end
end

local function matches_pattern(filename, patterns)
  for _, pattern in ipairs(patterns) do
    local regex_pattern = pattern:gsub('%.', '\\.'):gsub('%*', '.*')
    if vim.fn.match(filename, regex_pattern) ~= -1 then
      return true
    end
  end
  return false
end

local function is_sensitive_key(key)
  local lower_key = key:lower()
  for _, pattern in ipairs(SENSITIVE_KEY_PATTERNS) do
    local lower_pattern = pattern:lower()
    if lower_key:find(lower_pattern, 1, true) then
      return true
    end
  end
  return false
end

local function cloak_json_value(line, bufnr, line_num)
  local key_pattern = '["\']([^"\']+)["\']%s*:%s*'
  local search_start = 1

  while true do
    local key_start, key_end, key = string.find(line, key_pattern, search_start)
    if not key_start then
      break
    end

    if is_sensitive_key(key) then
      local colon_pos = string.find(line, ':', key_start)
      if colon_pos then
        local first_quote = string.find(line, '["\']', colon_pos + 1)
        if first_quote then
          local value_start = first_quote + 1
          local quote_char = string.sub(line, first_quote, first_quote)
          local end_quote = string.find(line, quote_char, value_start, true)
          if end_quote then
            M.cloak_line(bufnr, line_num, value_start - 1, end_quote - 1)
          end
        end
      end
    end

    search_start = key_end + 1
  end
end

local function cloak_yaml_value(line, bufnr, line_num)
  local key_pattern = '^(%s*)([%w_%-]+)%s*:%s*(.*)$'
  local indent, key, rest = string.match(line, key_pattern)

  if not key or rest == '' then
    return
  end

  if not is_sensitive_key(key) then
    return
  end

  local colon_pos = string.find(line, ':', #indent + 1)
  if not colon_pos then
    return
  end

  local value_start = colon_pos + 1
  while value_start <= #line and string.sub(line, value_start, value_start):match('%s') do
    value_start = value_start + 1
  end

  if value_start > #line then
    return
  end

  local first_char = string.sub(line, value_start, value_start)
  local value_end = #line + 1

  if first_char == '"' or first_char == "'" then
    local quote_char = first_char
    local end_quote = string.find(line, quote_char, value_start + 1, true)
    if end_quote then
      value_end = end_quote
    end
  else
    local whitespace_pos = string.find(line, '%s', value_start)
    local comment_pos = string.find(line, '#', value_start)

    if whitespace_pos and comment_pos then
      value_end = math.min(whitespace_pos, comment_pos)
    elseif whitespace_pos then
      value_end = whitespace_pos
    elseif comment_pos then
      value_end = comment_pos
    end
  end

  if value_end > value_start then
    M.cloak_line(bufnr, line_num, value_start - 1, value_end - 1)
  end
end

local function cloak_connection_string(line, bufnr, line_num)
  local pattern = '://([^:]+):([^@]+)@'
  local full_start, _, _, pass = string.find(line, pattern)

  if full_start and pass then
    local protocol_end = string.find(line, '://')
    if protocol_end then
      local user_start = protocol_end + 3
      local colon_pos = string.find(line, ':', user_start)
      if colon_pos then
        local pass_start = colon_pos + 1
        local at_pos = string.find(line, '@', pass_start)
        if at_pos then
          M.cloak_line(bufnr, line_num, pass_start - 1, at_pos - 1)
        end
      end
    end
  end
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
  else
    cloak_connection_string(line, bufnr, line_num)
  end
end

function M.cloak_buffer(bufnr)
  if not enabled then
    return
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local filename = vim.fs.basename(filepath)

  if not matches_pattern(filename, M.config.file_patterns) then
    return
  end

  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if filetype == 'env' or filename:match('%.env$') then
    for i, line in ipairs(lines) do
      local trimmed = trim_line(line)
      if trimmed ~= '' and trimmed:sub(1, 1) ~= '#' then
        cloak_env_value(trimmed, bufnr, i - 1)
      end
    end
  elseif filetype == 'json' or filename:match('%.json$') then
    for i, line in ipairs(lines) do
      local trimmed = trim_line(line)
      if trimmed ~= '' then
        cloak_json_value(trimmed, bufnr, i - 1)
      end
    end
  elseif filetype == 'yaml' or filetype == 'yml' or filename:match('%.ya?ml$') then
    for i, line in ipairs(lines) do
      local trimmed = trim_line(line)
      if trimmed ~= '' and trimmed:sub(1, 1) ~= '#' then
        cloak_yaml_value(trimmed, bufnr, i - 1)
      end
    end
  end
end

function M.toggle()
  enabled = not enabled
  if enabled then
    iter_loaded_buffers(function(bufnr)
      M.cloak_buffer(bufnr)
    end)
  else
    iter_loaded_buffers(function(bufnr)
      vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    end)
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

  return vim.api.nvim_buf_set_extmark(bufnr, namespace, line_num, start_col, {
    end_col = end_col,
    virt_text = { { cloak_text, 'Comment' } },
    virt_text_pos = 'overlay',
  })
end

local function clear_preview()
  if preview_active_bufnr and preview_line_num ~= nil and preview_extmarks then
    -- Clean up preview autocmd if exists
    if preview_autocmd_id then
      vim.api.nvim_del_autocmd(preview_autocmd_id)
      preview_autocmd_id = nil
    end

    -- Restore original extmarks
    for _, extmark_info in ipairs(preview_extmarks) do
      vim.api.nvim_buf_set_extmark(
        preview_active_bufnr,
        namespace,
        preview_line_num,
        extmark_info.start_col,
        {
          end_col = extmark_info.end_col,
          virt_text = { { extmark_info.cloak_text, 'Comment' } },
          virt_text_pos = 'overlay',
        }
      )
    end

    preview_active_bufnr = nil
    preview_line_num = nil
    preview_extmarks = {}
  end
end

local function get_line_extmarks(bufnr, line_num)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { line_num, 0 },
    { line_num, -1 },
    { details = true }
  )

  local cloak_extmarks = {}
  for _, extmark in ipairs(extmarks) do
    local _, _, start_col, details = unpack(extmark)
    if details and details.virt_text and #details.virt_text > 0 then
      table.insert(cloak_extmarks, {
        start_col = start_col,
        end_col = details.end_col,
        cloak_text = details.virt_text[1][1],
      })
    end
  end

  return cloak_extmarks
end

function M.preview_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1] - 1

  -- Get extmarks on current line
  local line_extmarks = get_line_extmarks(bufnr, line_num)

  -- Return early if no cloaked content on this line
  if #line_extmarks == 0 then
    clear_preview()
    return
  end

  -- Clear previous preview if active on different line
  if preview_active_bufnr and (preview_active_bufnr ~= bufnr or preview_line_num ~= line_num) then
    clear_preview()
  end

  -- If preview already active on this line, do nothing
  if preview_active_bufnr == bufnr and preview_line_num == line_num then
    return
  end

  -- Store extmark info and clear them to reveal content
  preview_active_bufnr = bufnr
  preview_line_num = line_num
  preview_extmarks = line_extmarks

  -- Clear all cloak extmarks on this line
  vim.api.nvim_buf_clear_namespace(bufnr, namespace, line_num, line_num + 1)

  -- Set up buffer-local InsertLeave autocmd to re-cloak when leaving insert mode
  preview_autocmd_id = vim.api.nvim_create_autocmd('InsertLeave', {
    buffer = bufnr,
    callback = function()
      clear_preview()
    end,
    once = true,
  })

  -- Set up buffer cleanup autocmds to clear preview when leaving buffer
  vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWinLeave' }, {
    buffer = bufnr,
    callback = function()
      clear_preview()
    end,
    once = true,
  })
end

function M.preview_toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor_pos[1] - 1

  -- Get extmarks on current line
  local line_extmarks = get_line_extmarks(bufnr, line_num)

  -- If no cloaked content on this line, clear any existing preview and do nothing
  if #line_extmarks == 0 then
    clear_preview()
    return
  end

  -- If preview already active on this line, re-cloak it
  if preview_active_bufnr == bufnr and preview_line_num == line_num then
    clear_preview()
    return
  end

  -- Otherwise, clear previous preview (if any) and reveal this line
  clear_preview()
  M.preview_line()
end

function M.setup(opts)
  opts = opts or {}
  local config = vim.tbl_deep_extend('force', default_config, opts)
  M.config = config

  enabled = true

  vim.api.nvim_create_augroup('TinyCloak', { clear = true })

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

  vim.api.nvim_create_autocmd('InsertEnter', {
    group = 'TinyCloak',
    pattern = config.file_patterns,
    callback = function(args)
      if not enabled then
        return
      end
      local bufnr = args.buf
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local line_num = cursor_pos[1] - 1
      local line_extmarks = get_line_extmarks(bufnr, line_num)
      if #line_extmarks > 0 then
        M.preview_line()
      end
    end,
  })

  vim.api.nvim_create_user_command('CloakToggle', M.toggle, {})
  vim.api.nvim_create_user_command('CloakEnable', M.enable, {})
  vim.api.nvim_create_user_command('CloakDisable', M.disable, {})
  vim.api.nvim_create_user_command('CloakPreviewToggle', M.preview_toggle, {})
end

return M
