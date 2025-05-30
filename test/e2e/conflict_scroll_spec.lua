local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local utils = require 'test.e2e.test_utils'

describe('Conflict scroll', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
  end)


  it('Keeps cursor in sync in both buffers', function()
    utils.open_file(nvim, './test/fixtures/conflict_other.txt')
    eq(1, utils.get_current_line(nvim))
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')
    eq(2, utils.get_current_line(nvim))
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    eq(2, utils.get_current_line(nvim))
  end)

  it('Keeps cursor in sync in both buffers during jump', function()
    utils.open_file(nvim, './test/fixtures/conflict_jump.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(4, utils.get_current_line(nvim))
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    eq(4, utils.get_current_line(nvim))
  end)
end)
