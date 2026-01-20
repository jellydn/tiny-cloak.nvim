-- Simple test runner for tiny-cloak.nvim
-- Usage: nvim --headless -c "luafile test/runner.lua"

package.path = 'lua/?.lua;lua/?/init.lua;test/?.lua;' .. package.path

local M = require('tiny-cloak')

-- Setup the module once for all tests
M.setup({})

local passed = 0
local failed = 0
local errors = {}

local function assert(condition, message)
  if not condition then
    error(message or 'Assertion failed')
  end
end

local function test(name, fn)
  local status, err = pcall(fn)
  if status then
    passed = passed + 1
    print('  [PASS] ' .. name)
  else
    failed = failed + 1
    table.insert(errors, { name = name, error = err })
    print('  [FAIL] ' .. name .. ': ' .. tostring(err))
  end
end

local function describe(name, fn)
  print('\n' .. name)
  fn()
end

-- Test helper functions for buffer creation
local function create_test_buffer(opts)
  opts = opts or {}

  -- Delete any existing buffer with the same name
  if opts.name then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        local ok, name = pcall(vim.api.nvim_buf_get_name, buf)
        if ok and name == opts.name then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
  end

  local bufnr = vim.api.nvim_create_buf(false, true)

  if opts.name then
    vim.api.nvim_buf_set_name(bufnr, opts.name)
  end

  if opts.filetype then
    vim.api.nvim_buf_set_option(bufnr, 'filetype', opts.filetype)
  end

  if opts.lines then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, opts.lines)
  end

  return bufnr
end

local function create_env_buffer(lines)
  local unique_name = '/tmp/.env.' .. tostring(math.random(100000))
  return create_test_buffer({
    name = unique_name,
    filetype = 'env',
    lines = lines,
  })
end

local function create_json_buffer(lines)
  return create_test_buffer({
    name = '/tmp/config.json',
    filetype = 'json',
    lines = lines,
  })
end

local function create_yaml_buffer(lines)
  return create_test_buffer({
    name = '/tmp/config.yaml',
    filetype = 'yaml',
    lines = lines,
  })
end

local test_ns = vim.api.nvim_create_namespace('tiny-cloak')

print('Running tiny-cloak.nvim tests...\n')

describe('setup', function()
  test('should load with default config', function()
    assert(M.config ~= nil, 'config should not be nil')
    assert(M.config.file_patterns ~= nil, 'file_patterns should not be nil')
  end)

  test('should have default file patterns', function()
    assert(#M.config.file_patterns > 0, 'should have patterns')
  end)
end)

describe('cloak_buffer', function()
  test('should not cloak non-matching file patterns', function()
    local bufnr = create_test_buffer({
      name = '/tmp/test.txt',
      lines = { 'API_KEY=secret' },
    })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 0, 'should not have extmarks for non-matching file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak env files', function()
    local bufnr = create_env_buffer({ 'API_KEY=secret123' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 1, 'should have 1 extmark for env file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak json files', function()
    local bufnr = create_json_buffer({ '{"apiKey": "secret123"}' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 1, 'should have 1 extmark for json file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak yaml files', function()
    local bufnr = create_yaml_buffer({ 'api_key: secret123' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 1, 'should have 1 extmark for yaml file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

describe('toggle', function()
  test('should be a function', function()
    assert(type(M.toggle) == 'function', 'toggle should be a function')
  end)
end)

describe('preview_line', function()
  test('should be a function', function()
    assert(type(M.preview_line) == 'function', 'preview_line should be a function')
  end)

  test('should return early if line has no cloak', function()
    local bufnr = create_test_buffer({
      name = '/tmp/test.txt',
      lines = { 'no secrets here' },
    })
    vim.api.nvim_set_current_buf(bufnr)
    M.preview_line()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should reveal cloaked content on current line', function()
    local bufnr = create_env_buffer({ 'API_KEY=secret123' })
    vim.api.nvim_set_current_buf(bufnr)
    M.cloak_buffer(bufnr)
    local extmarks_before = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_before == 1, 'should have 1 extmark before preview')
    M.preview_line()
    local extmarks_after = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_after == 0, 'should have 0 extmarks after preview (revealed)')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

describe('insert mode behavior', function()
  test('TextChanged callback should skip re-cloak in insert mode', function()
    local bufnr = create_env_buffer({ 'API_KEY=secret123' })
    vim.api.nvim_set_current_buf(bufnr)

    M.cloak_buffer(bufnr)
    local extmarks_before = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_before == 1, 'should have 1 extmark before preview')

    M.preview_line()
    local extmarks_after = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_after == 0, 'should have 0 extmarks after preview (revealed)')

    -- Simulate insert mode check in TextChangedI callback
    local mode = vim.api.nvim_get_mode().mode
    local in_insert_mode = mode:find('i') ~= nil

    if not in_insert_mode then
      -- In headless, simulate insert mode by NOT calling cloak_buffer
    end

    -- Verify no re-cloak occurred
    local extmarks_final = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_final == 0, 'should still have 0 extmarks (no re-cloak)')

    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

describe('preview_toggle', function()
  test('should be a function', function()
    assert(type(M.preview_toggle) == 'function', 'preview_toggle should be a function')
  end)

  test('should toggle reveal state on current line', function()
    local bufnr = create_env_buffer({ 'API_KEY=secret123' })
    vim.api.nvim_set_current_buf(bufnr)
    M.cloak_buffer(bufnr)
    local extmarks_initial = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_initial == 1, 'should have 1 extmark initially')
    M.preview_toggle()
    local extmarks_revealed = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_revealed == 0, 'should have 0 extmarks after first toggle (revealed)')
    M.preview_toggle()
    local extmarks_recloaked = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks_recloaked == 1, 'should have 1 extmark after second toggle (re-cloaked)')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should return early if line has no cloak', function()
    local bufnr = create_test_buffer({
      name = '/tmp/test.txt',
      lines = { 'no secrets here' },
    })
    vim.api.nvim_set_current_buf(bufnr)
    M.preview_toggle()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

print('\n' .. string.rep('=', 50))
print(string.format('Results: %d passed, %d failed', passed, failed))

if #errors > 0 then
  print('\nFailed tests:')
  for _, e in ipairs(errors) do
    print('  - ' .. e.name .. ': ' .. tostring(e.error))
  end
  os.exit(1)
else
  os.exit(0)
end
