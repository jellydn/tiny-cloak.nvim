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
  end)

  describe('cloak_line', function()
    it('should be a function', function()
      assert.is_function(M.cloak_line)
    end)
  end)

  describe('toggle', function()
    it('should be a function', function()
      assert.is_function(M.toggle)
    end)
  end)

  describe('enable', function()
    it('should be a function', function()
      assert.is_function(M.enable)
    end)
  end)

  describe('disable', function()
    it('should be a function', function()
      assert.is_function(M.disable)
    end)
  end)

  describe('cloak_buffer', function()
    it('should be a function', function()
      assert.is_function(M.cloak_buffer)
    end)
  end)
end)
