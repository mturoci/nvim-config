local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = {}
local original_file_content_ours_longer = {}
local fixture_file = './test/fixtures/conflict_other.txt'
local fixture_file_ours_longer = './test/fixtures/conflict_ours_longer.txt'

describe('Conflict editing', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
    original_file_content = vim.fn.readfile(fixture_file)
    original_file_content_ours_longer = vim.fn.readfile(fixture_file_ours_longer)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
    vim.fn.writefile(original_file_content, fixture_file)
    vim.fn.writefile(original_file_content_ours_longer, fixture_file_ours_longer)
  end)


  it('Changes file contents outside the conflict in the other buf and the original', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'iFoo bar', 'x', false)

    local expected = 'Foo barRegular text.\nOurs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Foo barRegular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 3, 0, -1, false)
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

  it('Changes file contents inside the conflict in the other buf and the original - ours longer #run', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dw')

    local expected = 'conflict.\nOurs conflict.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Theirs conflict.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 3, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    -- expected = [[
    -- Foo barRegular text.
    -- <<<<<<< HEAD
    -- Ours conflict.
    -- =======
    -- Theirs conflict.
    -- >>>>>>> another-branch
    -- Regular text.]]
    -- result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    -- eq(expected, table.concat(result, '\n'))
  end)

  it('Changes file contents at the end, outside the conflict in the other buf and the original - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal G')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'oFoo bar', 'x', false)

    local expected = 'Regular text.\nTheirs conflict.\nRegular text.\nFoo bar'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Regular text.\nOurs conflict.\nRegular text.\nFoo bar'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.
Foo bar]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Changes file contents at the end, inside the conflict in the other buf and the original', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'iFoo bar', 'x', false)

    local expected = 'Regular text.\nFoo barOurs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 3, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Foo barOurs conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row at the end - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal G')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\nTheirs conflict.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row inside the conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row inside the conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row outside the conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = 'Theirs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 1, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Undoes change outside of conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = 'Theirs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Undoes change inside of conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = "Regular text.\nRegular text."
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = [[
Regular text.
Theirs conflict.
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Undoes change outside of conflict left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = 'Ours conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = 'Regular text.\nOurs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Undoes change inside of conflict left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = "Regular text.\nRegular text."
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = [[
Regular text.
Ours conflict.
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Redoes change outside of conflict - right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = 'Theirs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-r>')
    expected = 'Theirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Redoes change inside of conflict right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'A Foo bar.', 'x', false)

    local expected = "Regular text.\nTheirs conflict. Foo bar.\nRegular text."
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = "Regular text.\nTheirs conflict.\nRegular text."
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-r>')
    expected = "Regular text.\nTheirs conflict. Foo bar.\nRegular text."
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Redoes change outside of conflict left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = 'Ours conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = 'Regular text.\nOurs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-r>')
    expected = 'Ours conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Redoes change inside of conflict left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'A Foo bar.', 'x', false)

    local expected = "Regular text.\nOurs conflict. Foo bar.\nRegular text."
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = "Regular text.\nOurs conflict.\nRegular text."
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-r>')
    expected = "Regular text.\nOurs conflict. Foo bar.\nRegular text."
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)
end)
