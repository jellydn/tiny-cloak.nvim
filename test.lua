-- LuaRocks test wrapper
-- This file works with both nvim and regular Lua

package.path = 'lua/?.lua;lua/?/init.lua;test/?.lua;' .. package.path

if vim and vim.cmd then
  vim.cmd("luafile test/runner.lua")
else
  -- State tracking for mocks
  local mock_state = {
    extmarks = {},
    lines = nil,
    namespace = nil,
    buf_name = '/tmp/.env',
    buf_filetype = 'env',
  }

  -- Simple vim-like regex matcher for our specific patterns
  local function vim_regex_match(str, vim_pattern)
    if vim_pattern == '.*\\.json' then
      return str:match('.*%.json$') ~= nil
    elseif vim_pattern == '.*\\.yaml' then
      return str:match('.*%.yaml$') ~= nil
    elseif vim_pattern == '.*\\.yml' then
      return str:match('.*%.yml$') ~= nil
    elseif vim_pattern == '\\.env.*' then
      return str:match('^%.env') ~= nil
    elseif vim_pattern == '.*\\.ya?ml' then
      return str:match('.*%.ya?ml$') ~= nil
    end
    return false
  end

  -- Mock vim for regular Lua (used by LuaRocks)
  _G.vim = {
    api = {
      nvim_create_buf = function() return 1 end,
      nvim_buf_set_name = function(bufnr, name)
        mock_state.buf_name = name
      end,
      nvim_buf_set_option = function(bufnr, option, value)
        if option == 'filetype' then
          mock_state.buf_filetype = value
        end
      end,
      nvim_buf_set_lines = function(bufnr, start, end_, strict, lines)
        mock_state.lines = lines
      end,
      nvim_buf_get_lines = function() return mock_state.lines or {} end,
      nvim_buf_is_valid = function() return true end,
      nvim_buf_delete = function() end,
      nvim_buf_get_extmarks = function(bufnr, ns, start, end_, opts)
        return mock_state.extmarks
      end,
      nvim_buf_set_extmark = function(bufnr, ns, line, col, opts)
        table.insert(mock_state.extmarks, { ns, line, col, opts or {} })
      end,
      nvim_buf_clear_namespace = function(bufnr, ns, start, end_)
        mock_state.extmarks = {}
      end,
      nvim_buf_get_name = function(bufnr) return mock_state.buf_name end,
      nvim_buf_get_option = function(bufnr, option)
        if option == 'filetype' then return mock_state.buf_filetype end
        return nil
      end,
      nvim_list_bufs = function() return {} end,
      nvim_buf_is_loaded = function(bufnr) return true end,
      nvim_get_current_buf = function() return 1 end,
      nvim_create_namespace = function(name)
        if not mock_state.namespace then
          mock_state.namespace = math.random(1, 100000)
        end
        return mock_state.namespace
      end,
      nvim_get_commands = function() return {} end,
      nvim_create_autocmd = function() end,
      nvim_create_augroup = function() return 'TinyCloak' end,
      nvim_create_user_command = function() end,
      nvim_set_current_buf = function() end,
    },
    fn = {
      match = function(str, pattern)
        return vim_regex_match(str, pattern) and 0 or -1
      end,
    },
    fs = {
      basename = function(path) return path:match('([^/]+)$') or path end,
    },
    bo = {},
    cmd = function() end,
    tbl_deep_extend = function(force, ...)
      local result = {}
      for i = 1, select('#', ...) do
        local tbl = select(i, ...)
        if tbl then
          for k, v in pairs(tbl) do
            if type(v) == 'table' and type(result[k]) == 'table' then
              result[k] = vim.tbl_deep_extend(force, result[k], v)
            else
              result[k] = v
            end
          end
        end
      end
      return result
    end,
    uv = { os_uname = function() return { sysname = 'Linux' } end },
    loop = { os_uname = function() return { sysname = 'Linux' } end },
    opt = { buflisted = {}, buftype = {} },
    g = {},
  }

  -- Run tests inline (don't call runner.lua which has os.exit)
  local M = require('tiny-cloak')
  local passed, failed = 0, 0

  local function assert(condition, message)
    if not condition then error(message or 'Assertion failed') end
  end

  local function test(name, fn)
    mock_state.extmarks = {}
    mock_state.lines = nil
    mock_state.buf_name = '/tmp/.env'
    mock_state.buf_filetype = 'env'
    local ok, err = pcall(fn)
    if ok then
      passed = passed + 1
      print('  [PASS] ' .. name)
    else
      failed = failed + 1
      print('  [FAIL] ' .. name .. ': ' .. tostring(err))
    end
  end

  print('Running tiny-cloak.nvim tests...\n')

  print('setup')
  test('should load with default config', function()
    M.setup({})
    assert(M.config ~= nil)
    assert(M.config.file_patterns ~= nil)
  end)
  test('should have default file patterns', function()
    assert(#M.config.file_patterns > 0)
  end)

  print('\ncloak_buffer')
  test('should not cloak non-matching file patterns', function()
    local bufnr = 1
    M.cloak_buffer(bufnr)
    assert(#mock_state.extmarks == 0)
  end)
  test('should cloak env files', function()
    local bufnr = 1
    mock_state.buf_name = '/tmp/.env'
    mock_state.buf_filetype = 'env'
    mock_state.lines = { 'API_KEY=secret123' }
    M.cloak_buffer(bufnr)
    assert(#mock_state.extmarks >= 1, 'expected extmarks, got ' .. #mock_state.extmarks)
  end)
  test('should cloak yaml files', function()
    local bufnr = 1
    mock_state.buf_name = '/tmp/config.yaml'
    mock_state.buf_filetype = 'yaml'
    mock_state.lines = { 'api_key: secret123' }
    M.cloak_buffer(bufnr)
    assert(#mock_state.extmarks >= 1, 'expected extmarks, got ' .. #mock_state.extmarks)
  end)

  print('\n' .. string.rep('=', 50))
  print(string.format('Results: %d passed, %d failed', passed, failed))

  if failed > 0 then os.exit(1) else os.exit(0) end
end
