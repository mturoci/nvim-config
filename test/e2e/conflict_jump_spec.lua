local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal

describe('Conflict', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
  end)


  it('Starts with cursor at the first line', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    eq(1, vim.fn.rpcrequest(nvim, 'nvim_eval', 'line(".")'))
  end)

  it('Jumps to next conflict when [c is hit #run', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    eq(2, vim.fn.rpcrequest(nvim, 'nvim_eval', 'line(".")'))
  end)
end)
