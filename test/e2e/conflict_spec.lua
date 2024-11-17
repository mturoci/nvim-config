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

  it('Renders proper buffer content for left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq('Ours conflict.', table.concat(result, '\n'))
  end)

  it('Renders proper buffer content for longer left side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_ours_longer.txt')
    local lhs = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    local rhs = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq('Ours conflict.\nOurs conflict.', table.concat(lhs, '\n'))
    eq('Theirs conflict.\n', table.concat(rhs, '\n'))
  end)

  it('Renders proper buffer content for left side with non-conflict text as well', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Renders proper buffer content for longer right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_theirs_longer.txt')
    local rhs = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    local lhs = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 2, 0, -1, false)
    eq('Theirs conflict.\nTheirs conflict.', table.concat(rhs, '\n'))
    eq('Ours conflict.\n', table.concat(lhs, '\n'))
  end)

  it('Renders proper buffer content for right side', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq('Theirs conflict.', table.concat(result, '\n'))
  end)

  it('Renders proper buffer content for right side with non-conflict text as well', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq('Regular text.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Highlights conflict on rhs properly', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(1, #marks)
    eq(2, marks[1][2])
  end)

  it('Highlights conflict on lhs properly', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_other.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(1, #marks)
    eq(2, marks[1][2])
  end)

  it('Highlights conflict on lhs properly when ours is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_ours_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(2, #marks)
    eq(1, marks[1][2])
    eq(2, marks[2][2])
  end)

  it('Highlights conflict on rhs properly when ours is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_ours_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(2, #marks)
    eq(1, marks[1][2])
    eq(2, marks[2][2])
  end)

  it('Highlights conflict on lhs properly when theirs is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_theirs_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(2, #marks)
    eq(1, marks[1][2])
    eq(2, marks[2][2])
  end)

  it('Highlights conflict on rhs properly when theirs is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_theirs_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is_not.truthy(mark2Namespace)
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(2, #marks)
    eq(1, marks[1][2])
    eq(2, marks[2][2])
  end)

  it('Highlights multiple conflicts properly on rhs', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(1, #marks1)
    eq(2, marks1[1][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(1, #marks2)
    eq(4, marks2[1][2])
  end)

  it('Highlights multiple conflicts properly on lhs', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(1, #marks1)
    eq(2, marks1[1][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(1, #marks2)
    eq(4, marks2[1][2])
  end)


  it('Highlights multiple conflicts properly on rhs when theirs is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple_theirs_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(2, #marks1)
    eq(1, marks1[1][2])
    eq(2, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(4, marks2[1][2])
    eq(5, marks2[2][2])
  end)

  it('Highlights multiple conflicts properly on lhs when theirs is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple_theirs_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(2, #marks1)
    eq(1, marks1[1][2])
    eq(2, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(4, marks2[1][2])
    eq(5, marks2[2][2])
  end)

  it('Highlights multiple conflicts properly on rhs when ours is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple_ours_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(2, #marks1)
    eq(1, marks1[1][2])
    eq(2, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(4, marks2[1][2])
    eq(5, marks2[2][2])
  end)

  it('Highlights multiple conflicts properly on lhs when ours is longer', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ./test/fixtures/conflict_multiple_ours_longer.txt')
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    assert.is.truthy(mark1Namespace)
    local mark2Namespace = ns['conflict_mark:2']
    assert.is.truthy(mark2Namespace)
    local mark3Namespace = ns['conflict_mark:3']
    assert.is_not.truthy(mark3Namespace)
    local marks1 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    eq(2, #marks1)
    eq(1, marks1[1][2])
    eq(2, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(4, marks2[1][2])
    eq(5, marks2[2][2])
  end)
end)
