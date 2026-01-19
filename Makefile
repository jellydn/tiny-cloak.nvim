.PHONY: all test test-file format lint clean install dev-deps

all: test

test:
	busted

test-file:
	busted test/plugin_spec.lua

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
