local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = {}
local fixture_file = './test/fixtures/conflict_other.txt'

describe('Conflict editing', function()
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


  it('Changes file contents outside the conflict in the other buf and the original', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'iFoo bar', 'x', false)

    local expected = 'Foo barRegular text.\nTheirs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Foo barRegular text.\nOurs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Foo barRegular text.
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)
end)
