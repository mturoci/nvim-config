local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }

local function count_hidden_bufs(bufs)
  local count = 0
  for _, buf in ipairs(bufs) do
    if buf.hidden == 0 then
      count = count + 1
    end
  end
  return count
end

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
    assert.is.equal(3, bufCount)
  end)

  it('Sets a buffer file type', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_eval', '&filetype')
    assert.is.equal('text', result)
  end)

  it('Closes both buffers when closing the left one', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'getbufinfo()')
    assert.is.equal(3, count_hidden_bufs(bufs))
    vim.fn.rpcrequest(nvim, 'nvim_command', 'q')
    bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'getbufinfo()')
    assert.is.equal(1, count_hidden_bufs(bufs))
  end)

  it('Closes both buffers when closing the right one', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'getbufinfo()')
    assert.is.equal(3, count_hidden_bufs(bufs))
    vim.fn.rpcrequest(nvim, 'nvim_command', 'wincmd w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'q')
    bufs = vim.fn.rpcrequest(nvim, 'nvim_eval', 'getbufinfo()')
    assert.is.equal(1, count_hidden_bufs(bufs))
  end)
end)
