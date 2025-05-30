local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = {}
local fixture_file = './test/fixtures/conflict_other.txt'
local utils = require 'test.e2e.test_utils'
local nvim

local function get_current_line()
  if not nvim then error('nvim is not initialized') end

  vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
  return vim.fn.rpcrequest(nvim, 'nvim_eval', 'line(".")')
end

describe('Conflict jumps #run', function()
  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
    original_file_content = vim.fn.readfile(fixture_file)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
    vim.fn.writefile(original_file_content, fixture_file)
  end)


  it('Starts with cursor at the first line', function()
    utils.open_file(nvim, './test/fixtures/conflict_jump.txt')
    eq(1, vim.fn.rpcrequest(nvim, 'nvim_eval', 'line(".")'))
  end)

  it('Jumps to next conflict when [c is hit', function()
    utils.open_file(nvim, './test/fixtures/conflict_jump.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(2, get_current_line())
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(4, get_current_line())
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(6, get_current_line())
    -- Wraps around.
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(2, get_current_line())
  end)

  it('Jumps to prev conflict when ]c is hit', function()
    utils.open_file(nvim, './test/fixtures/conflict_jump.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', ']c')
    -- Wraps around.
    eq(6, get_current_line())
    vim.fn.rpcrequest(nvim, 'nvim_input', ']c')
    eq(4, get_current_line())
    vim.fn.rpcrequest(nvim, 'nvim_input', ']c')
    eq(2, get_current_line())
    -- Wraps around.
    vim.fn.rpcrequest(nvim, 'nvim_input', ']c')
    eq(6, get_current_line())
  end)

  it('Stays in place if there is nowhere to jump anymore', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(2, get_current_line())

    local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'a', true, false, true), 'm',
      true)

    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')

    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(2, get_current_line())
    vim.fn.rpcrequest(nvim, 'nvim_input', ']c')
    eq(2, get_current_line())
  end)
end)
