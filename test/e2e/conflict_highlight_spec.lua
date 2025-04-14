local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local fixture_file = './test/fixtures/conflict_other.txt'

describe('Conflict highlight', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
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
    eq(1, marks[1][2])
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
    eq(1, marks[1][2])
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
    eq(0, marks[1][2])
    eq(1, marks[2][2])
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
    eq(0, marks[1][2])
    eq(1, marks[2][2])
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
    eq(0, marks[1][2])
    eq(1, marks[2][2])
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
    eq(0, marks[1][2])
    eq(1, marks[2][2])
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
    eq(1, marks1[1][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(1, #marks2)
    eq(3, marks2[1][2])
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
    eq(1, marks1[1][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(1, #marks2)
    eq(3, marks2[1][2])
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
    eq(0, marks1[1][2])
    eq(1, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(3, marks2[1][2])
    eq(4, marks2[2][2])
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
    eq(0, marks1[1][2])
    eq(1, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(3, marks2[1][2])
    eq(4, marks2[2][2])
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
    eq(0, marks1[1][2])
    eq(1, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(3, marks2[1][2])
    eq(4, marks2[2][2])
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
    eq(0, marks1[1][2])
    eq(1, marks1[2][2])
    local marks2 = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark2Namespace, 0, -1, {})
    eq(2, #marks2)
    eq(3, marks2[1][2])
    eq(4, marks2[2][2])
  end)

  it('Removes highlight after accepting conflict', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    -- Expect there to be a single highlight.
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(1, #marks)

    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'a', true, false, true), 'm',
      true)

    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')

    local left_marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    local right_marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 3, mark1Namespace, 0, -1, {})
    eq(0, #left_marks)
    eq(0, #right_marks)
  end)

  it('Removes highlight after accepting both conflicts', function()
    vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. fixture_file)
    -- Expect there to be a single highlight.
    local ns = vim.fn.rpcrequest(nvim, 'nvim_get_namespaces')
    local mark1Namespace = ns['conflict_mark:1']
    local marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 0, mark1Namespace, 0, -1, {})
    eq(1, #marks)

    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'b', true, false, true), 'm',
      true)

    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')

    local left_marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 2, mark1Namespace, 0, -1, {})
    local right_marks = vim.fn.rpcrequest(nvim, 'nvim_buf_get_extmarks', 3, mark1Namespace, 0, -1, {})
    eq(0, #left_marks)
    eq(0, #right_marks)
  end)
end)
