.PHONY: all test test-file format lint clean install dev-deps help

all: test

test:
	nvim --headless -c "luafile test/runner.lua" -c "qall!"

test-file:
	nvim --headless -c "luafile test/runner.lua" -c "qall!"

format:
	stylua lua/ test/

lint:
	stylua --check lua/ test/

clean:
	rm -rf .luarocks

install:
	luarocks install tiny-cloak.nvim-1.0.0-1.rockspec

dev-deps:
	luarocks install --deps-only tiny-cloak.nvim-1.0.0-1.rockspec

help:
	@echo "Available targets:"
	@echo "  make test        - Run all tests"
	@echo "  make test-file   - Run test file"
	@echo "  make format      - Format Lua files"
	@echo "  make lint        - Check formatting"
	@echo "  make install     - Install with LuaRocks"
	@echo "  make dev-deps    - Install development dependencies"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make help        - Show this help"
