local M = require('tiny-cloak')

describe('tiny-cloak', function()
  before_each(function()
    M.setup({})
  end)

  describe('setup', function()
    it('should load with default config', function()
      assert.is_not_nil(M.config)
      assert.is_not_nil(M.config.file_patterns)
      assert.is_not_nil(M.config.cloak_character)
      assert.is_not_nil(M.config.key_patterns)
    end)

    it('should have default file patterns', function()
      assert.are.same({ '.env*', '*.json', '*.yaml', '*.yml' }, M.config.file_patterns)
    end)

    it('should have default cloak character', function()
      assert.are.equal('*', M.config.cloak_character)
    end)

    it('should have default key patterns', function()
      local expected = { 'API_KEY', 'SECRET', 'PASSWORD', 'TOKEN', 'CREDENTIAL', 'AUTH' }
      assert.are.same(expected, M.config.key_patterns)
    end)

    it('should allow custom config', function()
      M.setup({
        cloak_character = '#',
        key_patterns = { 'CUSTOM_KEY' },
      })
      assert.are.equal('#', M.config.cloak_character)
      assert.are.same({ 'CUSTOM_KEY' }, M.config.key_patterns)
    end)

    it('should merge custom config with defaults', function()
      M.setup({
        cloak_character = '@',
      })
      assert.are.equal('@', M.config.cloak_character)
      assert.are.same({ '.env*', '*.json', '*.yaml', '*.yml' }, M.config.file_patterns)
    end)

    it('should allow custom file patterns', function()
      M.setup({
        file_patterns = { '.env', '.secrets' },
      })
      assert.are.same({ '.env', '.secrets' }, M.config.file_patterns)
    end)

    it('should create user commands', function()
      assert.is_not_nil(vim.api.nvim_get_commands({})['CloakToggle'])
      assert.is_not_nil(vim.api.nvim_get_commands({})['CloakEnable'])
      assert.is_not_nil(vim.api.nvim_get_commands({})['CloakDisable'])
    end)
  end)

  describe('cloak_line', function()
    it('should be a function', function()
      assert.is_function(M.cloak_line)
    end)

    it('should create extmark with correct cloak text length', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret123' })

      M.cloak_line(bufnr, 0, 8, 17)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })

      assert.are.equal(1, #extmarks)
      assert.are.equal(0, extmarks[1][2])
      assert.are.equal(8, extmarks[1][3])

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should use configured cloak character', function()
      M.setup({ cloak_character = '#' })

      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=test' })

      M.cloak_line(bufnr, 0, 8, 12)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })

      assert.are.equal(1, #extmarks)
      local virt_text = extmarks[1][4].virt_text[1][1]
      assert.are.equal('####', virt_text)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe('toggle', function()
    it('should be a function', function()
      assert.is_function(M.toggle)
    end)

    it('should toggle cloaking state', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/test.env')
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret' })
      vim.api.nvim_set_current_buf(bufnr)

      M.toggle()
      M.toggle()

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe('enable', function()
    it('should be a function', function()
      assert.is_function(M.enable)
    end)

    it('should enable cloaking when disabled', function()
      M.disable()
      M.enable()
    end)

    it('should do nothing when already enabled', function()
      M.enable()
      M.enable()
    end)
  end)

  describe('disable', function()
    it('should be a function', function()
      assert.is_function(M.disable)
    end)

    it('should disable cloaking when enabled', function()
      M.enable()
      M.disable()
    end)

    it('should do nothing when already disabled', function()
      M.disable()
      M.disable()
    end)
  end)

  describe('cloak_buffer', function()
    it('should be a function', function()
      assert.is_function(M.cloak_buffer)
    end)

    it('should not cloak non-matching file patterns', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/test.txt')
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(0, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak env files', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret123' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should skip comments in env files', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '# API_KEY=secret123' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(0, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should skip empty lines', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '', 'API_KEY=secret', '' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak json files with sensitive keys', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
      vim.bo[bufnr].filetype = 'json'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '{"apiKey": "secret123"}' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak yaml files with sensitive keys', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'api_key: secret123' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak yml files', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'password: mypassword' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak connection strings in env files', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(
        bufnr,
        0,
        -1,
        false,
        { 'DATABASE_URL=postgres://user:password@localhost' }
      )

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.is_true(#extmarks >= 1)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should not cloak when disabled', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'API_KEY=secret' })

      M.disable()
      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(0, #extmarks)

      M.enable()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should use current buffer when bufnr is nil', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'SECRET=value' })
      vim.api.nvim_set_current_buf(bufnr)

      M.cloak_buffer()

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak multiple sensitive keys', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        'API_KEY=key1',
        'SECRET=secret1',
        'PASSWORD=pass1',
      })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(3, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak TOKEN pattern', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'TOKEN=abc123' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak CREDENTIAL pattern', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'CREDENTIAL=mycred' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak AUTH pattern', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/.env')
      vim.bo[bufnr].filetype = 'env'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'AUTH=myauth' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe('json cloaking', function()
    it('should cloak password in json', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
      vim.bo[bufnr].filetype = 'json'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '{"password": "secret"}' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak token in json', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
      vim.bo[bufnr].filetype = 'json'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '{"token": "abc123"}' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak secret in json', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
      vim.bo[bufnr].filetype = 'json'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '{"secret": "mysecret"}' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak single quoted values in json', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.json')
      vim.bo[bufnr].filetype = 'json'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "{'apiKey': 'secret123'}" })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  describe('yaml cloaking', function()
    it('should cloak quoted values in yaml', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'password: "quoted_secret"' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should skip yaml comments', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '# password: secret' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(0, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak indented yaml keys', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '  token: mytoken' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak credential in yaml', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'credential: mycred' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it('should cloak auth in yaml', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(bufnr, '/tmp/config.yaml')
      vim.bo[bufnr].filetype = 'yaml'
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'auth: myauth' })

      M.cloak_buffer(bufnr)

      local namespace = vim.api.nvim_create_namespace('tiny-cloak')
      local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
      assert.are.equal(1, #extmarks)

      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)
end)
