#!/usr/bin/env nvim
-- LuaRocks test wrapper
-- This file is executed by LuaRocks when running tests

vim.cmd("luafile test/runner.lua")
