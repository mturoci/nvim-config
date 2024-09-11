local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }

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
    local result = vim.fn.rpcrequest(nvim, 'nvim_eval', 'len(nvim_list_bufs())')

    assert.is.equal(3, result)
  end)

  it('Sets a buffer file type', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_eval', '&filetype')
    assert.is.equal('text', result)
  end)
end)
