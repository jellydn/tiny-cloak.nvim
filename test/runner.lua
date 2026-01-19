-- Simple test runner for tiny-cloak.nvim
-- Usage: nvim --headless -c "luafile test/runner.lua"

package.path = 'lua/?.lua;lua/?/init.lua;test/?.lua;' .. package.path

local M = require('tiny-cloak')

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

local test_ns = vim.api.nvim_create_namespace('tiny-cloak')

print('Running tiny-cloak.nvim tests...\n')

describe('setup', function()
  test('should load with default config', function()
    M.setup({})
    assert(M.config ~= nil, 'config should not be nil')
    assert(M.config.file_patterns ~= nil, 'file_patterns should not be nil')
  end)

  test('should have default file patterns', function()
    assert(#M.config.file_patterns > 0, 'should have patterns')
  end)
end)

describe('cloak_buffer', function()
  test('should not cloak non-matching file patterns', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/test.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 0, 'should not have extmarks for non-matching file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak env files', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'env')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret123' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 1, 'should have 1 extmark for env file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak json files', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'json')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '{"apiKey": "secret123"}' })
    M.cloak_buffer(bufnr)
    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, test_ns, 0, -1, {})
    assert(#extmarks == 1, 'should have 1 extmark for json file')
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should cloak yaml files', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'yaml')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'api_key: secret123' })
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
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/test.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'no secrets here' })
    vim.api.nvim_set_current_buf(bufnr)
    M.preview_line()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)

  test('should reveal cloaked content on current line', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'env')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret123' })
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

describe('preview_toggle', function()
  test('should be a function', function()
    assert(type(M.preview_toggle) == 'function', 'preview_toggle should be a function')
  end)

  test('should toggle reveal state on current line', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
    vim.api.nvim_buf_set_option(bufnr, 'filetype', 'env')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret123' })
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
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, '/tmp/test.txt')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'no secrets here' })
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
