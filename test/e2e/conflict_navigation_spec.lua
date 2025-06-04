local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local utils = require 'test.e2e.test_utils'

describe('Conflict navigation', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
  end)


  it('Do not jump to original buffer when using CTRL-W w', function()
    utils.open_file(nvim, './test/fixtures/conflict_other.txt')
    eq(2, vim.fn.rpcrequest(nvim, 'nvim_eval', 'bufnr("%")'))
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    eq(3, vim.fn.rpcrequest(nvim, 'nvim_eval', 'bufnr("%")'))
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    eq(2, vim.fn.rpcrequest(nvim, 'nvim_eval', 'bufnr("%")'))
  end)
end)
