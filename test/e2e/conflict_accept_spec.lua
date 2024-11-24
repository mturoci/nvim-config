local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = ''
local fixture_file = './test/fixtures/conflict_other.txt'

describe('Conflict accept', function()
  local nvim

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


  it('Accepts left conflict and updates all buffers properly #run', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'a', true, false, true), 'm',
      true)

    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    local expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)
end)
