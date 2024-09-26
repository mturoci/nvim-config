local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal

describe('Conflict', function()
  local nvim

  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
  end)

  after_each(function()
    vim.fn.jobstop(nvim)
  end)

  it('Opens 3 buffers when opening a file with git conflict', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local bufCount = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(nvim_list_bufs())')
    eq(3, bufCount)
  end)

  it('Sets a buffer file type', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_eval', '&filetype')
    eq('text', result)
  end)

  it('Closes both buffers when closing the left one', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local visible_bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(filter(getbufinfo(), "v:val.hidden == 0"))')
    eq(3, visible_bufs)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'q')
    visible_bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(filter(getbufinfo(), "v:val.hidden == 0"))')
    eq(1, visible_bufs)
  end)

  it('Closes both buffers when closing the right one', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local visible_bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(filter(getbufinfo(), "v:val.hidden == 0"))')
    eq(3, visible_bufs)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'wincmd w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'q')
    visible_bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(filter(getbufinfo(), "v:val.hidden == 0"))')
    eq(1, visible_bufs)
  end)
end)
