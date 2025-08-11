local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = {}
local original_file_content_ours_longer = {}
local original_file_content_multiple = {}
local original_file_content_multiple_ours_longer = {}
local original_fixture_file_empty = {}
local fixture_file = './test/fixtures/conflict_other.txt'
local fixture_file_ours_longer = './test/fixtures/conflict_ours_longer.txt'
local fixture_file_multiple = './test/fixtures/conflict_multiple.txt'
local fixture_file_multiple_ours_longer = './test/fixtures/conflict_multiple_ours_longer.txt'
local fixture_file_empty = './test/fixtures/conflict_empty.txt'
local utils = require 'test.e2e.test_utils'

describe('Conflict editing', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
    original_file_content = vim.fn.readfile(fixture_file)
    original_file_content_ours_longer = vim.fn.readfile(fixture_file_ours_longer)
    original_file_content_multiple = vim.fn.readfile(fixture_file_multiple)
    original_file_content_multiple_ours_longer = vim.fn.readfile(fixture_file_multiple_ours_longer)
    original_fixture_file_empty = vim.fn.readfile(fixture_file_empty)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
    vim.fn.writefile(original_file_content, fixture_file)
    vim.fn.writefile(original_file_content_ours_longer, fixture_file_ours_longer)
    vim.fn.writefile(original_file_content_multiple, fixture_file_multiple)
    vim.fn.writefile(original_file_content_multiple_ours_longer, fixture_file_multiple_ours_longer)
    vim.fn.writefile(original_fixture_file_empty, fixture_file_empty)
  end)


  it('Changes file contents outside the conflict in the other buf and the original', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'iFoo bar', 'x', false)

    local expected = 'Foo barRegular text.\nOurs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Foo barRegular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Foo barRegular text.
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Changes file contents inside the conflict in the other buf and the original - ours longer', function()
    utils.open_file(nvim, fixture_file_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dw')

    local expected = 'conflict.\nOurs conflict.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Theirs conflict.\n'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
<<<<<<< HEAD
conflict.
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Adds line inside the conflict in the other buf and the original - ours longer', function()
    utils.open_file(nvim, fixture_file_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal yy')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal p')

    local expected = 'Ours conflict.\nOurs conflict.\nOurs conflict.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Theirs conflict.\n\n'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
<<<<<<< HEAD
Ours conflict.
Ours conflict.
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Changes file contents at the end, outside the conflict in the other buf and the original - right side',
    function()
      utils.open_file(nvim, fixture_file)
      vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
      vim.fn.rpcrequest(nvim, 'nvim_command', 'normal G')
      -- Add sleep to wait for autocmds to be triggered.
      vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
      vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'oFoo bar', 'x', false)

      local expected = 'Regular text.\nTheirs conflict.\nRegular text.\nFoo bar'
      local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
      eq(expected, table.concat(result, '\n'))

      expected = 'Regular text.\nOurs conflict.\nRegular text.\nFoo bar'
      result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
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
      result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
      eq(expected, table.concat(result, '\n'))
    end)

  it('Changes file contents at the end, inside the conflict in the other buf and the original', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', 'iFoo bar', 'x', false)

    local expected = 'Regular text.\nFoo barOurs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Foo barOurs conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Adds a new line inside the conflict in the other buf and the original', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal yy')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal p')

    local expected = 'Regular text.\nOurs conflict.\nOurs conflict.\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Regular text.\nTheirs conflict.\n\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row at the end - right side', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal G')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\nTheirs conflict.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row inside the conflict - right side', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\n\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row inside the conflict - right side', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd') -- Remove the conflict row

    local expected = 'Regular text.\n\nRegular text.'
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = 'Regular text.\nOurs conflict.\nRegular text.'
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
Ours conflict.
=======
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Removes the row outside the conflict - right side', function()
    utils.open_file(nvim, fixture_file)
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
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Undoes change outside of conflict - right side', function()
    utils.open_file(nvim, fixture_file)
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
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = "Regular text.\n\nRegular text."
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
    utils.open_file(nvim, fixture_file)
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
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal dd')

    local expected = "Regular text.\n\nRegular text."
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    expected = [[
Regular text.
Ours conflict.
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Redoes change outside of conflict - right side', function()
    utils.open_file(nvim, fixture_file)
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
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
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
    utils.open_file(nvim, fixture_file)
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
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')
    -- Add sleep to wait for autocmds to be triggered.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
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

  it('Changes line count in first conflict and accepts second - left side, ours longer', function()
    utils.open_file(nvim, fixture_file_multiple_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal yy')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal p')

    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
    utils.accept_conflict(nvim)

    local expected = [[
Ours conflict.
Ours conflict.
Ours conflict.

Ours conflict.
Ours conflict.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Theirs conflict.



Ours conflict.
Ours conflict.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
<<<<<<< HEAD
Ours conflict.
Ours conflict.
Ours conflict.
=======
Theirs conflict.
>>>>>>> another-branch

Ours conflict.
Ours conflict.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Changes line count in first conflict and accepts second - right side, ours longer', function()
    utils.open_file(nvim, fixture_file_multiple_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal yy')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal p')

    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')
    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
    utils.accept_conflict(nvim)

    local expected = [[
Ours conflict.
Ours conflict.

Theirs conflict.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Theirs conflict.
Theirs conflict.

Theirs conflict.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
<<<<<<< HEAD
Ours conflict.
Ours conflict.
=======
Theirs conflict.
Theirs conflict.
>>>>>>> another-branch

Theirs conflict.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Renders empty conflict', function()
    utils.open_file(nvim, fixture_file_empty)

    local expected = [[
Regular text.

Regular text.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
Theirs conflict.
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    expected = [[
Regular text.
<<<<<<< HEAD
=======
Theirs conflict.
>>>>>>> another-branch
Regular text.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts left side empty conflict', function()
    utils.open_file(nvim, fixture_file_empty)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')

    utils.accept_conflict(nvim)
    local expected = [[
Regular text.
Regular text.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts right side empty conflict', function()
    utils.open_file(nvim, fixture_file_empty)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal j')

    utils.accept_conflict(nvim)
    local expected = [[
Regular text.
Theirs conflict.
Regular text.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)
end)
