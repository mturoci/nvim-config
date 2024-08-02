local conflicts = require('config.conflicts')
local tmp_file = '/tmp/conflicts.txt'

local function parse(content)
  local file = io.open(tmp_file, "w")
  if file then
    file:write(content)
    file:close()
  else
    error("Could not open file for writing.")
  end
  return conflicts.parse(tmp_file)
end

describe('Conflicts builder', function()
  after_each(function()
    if conflicts.file_exists(tmp_file) then
      assert(os.remove(tmp_file))
    end
  end)

  it('should parse a single conflict', function()
    local parsedConflict = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
This is some more text.
  ]])
    local expectedConflict = { {
      from = 2,
      to = 6,
      ours = { len = 1 },
      theirs = { len = 1 }
    } }
    assert.is.same(expectedConflict, parsedConflict)
  end)

  it('should parse multiple conflicts', function()
    local parsedConflicts = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
This is some more text.
<<<<<<< HEAD
This is some additional text from our branch.
=======
This is some additional text from their branch.
>>>>>>> branch-name
This is the end of the file.
]])
    assert.is.equal(2, #parsedConflicts)
  end)

  it('should parse a conflict with multiple lines', function()
    local conflicts = parse([[
This is some text.
This is some text.
<<<<<<< HEAD
This is some text from our branch.
This is some text from our branch.
=======
This is some text from their branch.
This is some text from our branch.
>>>>>>> branch-name
This is some more text.
]])
    local expectedConflict = {{
        from = 3,
        to = 9,
        ours = {len = 2},
        theirs = {len = 2}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)

  it('should return empty table when no conflicts are found', function()
    local expectedConflicts = parse([[
  This is some text.
  This is some text.
  This is some text.
  ]])
    assert.is.same({}, expectedConflicts)
  end)

  it('should return empty table when file is empty', function()
    local conflicts = parse('')
    assert.is.same({}, conflicts)
  end)

  it('should throw error when file does not exist', function()
    if pcall(conflicts.parse, 'non-existent-file.txt') then
      assert.is.falsy(true)
    else
      assert.is.truthy(true)
    end
  end)

  it('should parse a conflict with multiple lines and multiple conflicts', function()
    local expectedConflicts = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
This is some text from our branch.
=======
This is some text from their branch.
This is some text from our branch.
>>>>>>> branch-name
This is some more text.
<<<<<<< HEAD
This is some additional text from our branch.
This is some additional text from our branch.
=======
This is some additional text from their branch.
This is some additional text from their branch.
>>>>>>> branch-name
This is the end of the file.
]])
    local expectedConflict = {{
        from = 2,
        to = 8,
        ours = {len = 2},
        theirs = {len = 2}
    }, {
      from = 10,
      to = 16,
      ours = {len = 2},
      theirs = {len = 2}
    } }
    assert.is.same(expectedConflict, expectedConflicts)
  end)

  it('should parse conflict when at the beginning of the file', function()
    local conflicts = parse([[
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
This is some more text.
]])
    local expectedConflict = {{
        from = 1,
        to = 5,
        ours = {len = 1},
        theirs = {len = 1}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)

  it('should parse conflict when at the end of the file', function()
    local conflicts = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
]])
    local expectedConflict = {{
        from = 2,
        to = 6,
        ours = {len = 1},
        theirs = {len = 1}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)
end)

describe("Conflict updater", function()
  it("deletes lines inside conflict", function()
    local conflictsT = {
      {
        from = 1,
        to = 10,
        ours = {len = 4},
        theirs = {len = 3}
      }
    }
    conflicts.update_lines(conflictsT, 2, 3, 'ours', true)
    assert.are.same(conflictsT[1].to, 8)
    assert.are.same(conflictsT[1].ours.len, 2)
  end)

  it('deletes lines after conflict', function()
    local conflictsT = {
      {
        from = 1,
        to = 5,
        ours = {len = 1},
        theirs = {len = 1}
      }
    }
    conflicts.update_lines(conflictsT, 6, 7, 'ours', true)
    assert.are.same(conflictsT[1].to, 5)
    assert.are.same(conflictsT[1].ours.len, 1)
    assert.are.same(conflictsT[1].theirs.len, 1)
  end)

  it('deletes lines before conflict', function()
    local conflictsT = {
      {
        from = 3,
        to = 9,
        ours = {len = 2},
        theirs = {len = 1}
      }
    }
    conflicts.update_lines(conflictsT, 1, 2, 'ours', true)
    assert.are.same(conflictsT[1].from, 1)
    assert.are.same(conflictsT[1].to, 7)
    assert.are.same(conflictsT[1].ours.len, 2)
    assert.are.same(conflictsT[1].theirs.len, 1)
  end)

  it('deletes lines on the starting conflict intersection', function()
    local conflictsT = {
      {
        from = 3,
        to = 10,
        ours = {len = 3},
        theirs = {len = 2}
      }
    }
    conflicts.update_lines(conflictsT, 2, 4, 'ours', true)
    assert.are.same(conflictsT[1].from, 2)
    assert.are.same(conflictsT[1].to, 8)
    assert.are.same(conflictsT[1].ours.len, 1)
    assert.are.same(conflictsT[1].theirs.len, 2)
  end)

  it('deletes lines between two conflicts', function()
    local conflictsT = {
      {
        from = 1,
        to = 5,
        ours = {len = 1},
        theirs = {len = 1}
      },
      {
        from = 8,
        to = 12,
        ours = {len = 1},
        theirs = {len = 1}
      },
    }

    conflicts.update_lines(conflictsT, 6, 7, 'ours', true)
    assert.are.same(conflictsT[1], {
      from = 1,
      to = 5,
      ours = {len = 1},
      theirs = {len = 1}
    })
    assert.are.same(conflictsT[2], {
      from = 6,
      to = 10,
      ours = {len = 1},
      theirs = {len = 1}
    })
  end)

  it("adds lines correctly inside conflict", function()
    local conflictsT = {
      {
        from = 1,
        to = 10,
        ours = {len = 4},
        theirs = {len = 3}
      }
    }
    conflicts.update_lines(conflictsT, 2, 4, 'ours', false)
    assert.are.same(13, conflictsT[1].to)
    assert.are.same(7, conflictsT[1].ours.len)
  end)

  it('adds lines correctly after conflict', function()
    local conflictsT = {
      {
        from = 1,
        to = 5,
        ours = {len  = 1},
        theirs = {len  = 1}
      }
    }
    conflicts.update_lines(conflictsT, 6, 7, 'ours', false)
    assert.are.same(conflictsT[1].from, 1)
    assert.are.same(conflictsT[1].to, 5)
    assert.are.same(conflictsT[1].ours.len, 1)
    assert.are.same(conflictsT[1].theirs.len, 1)
  end)

  it('adds lines correctly before conflict', function()
    local conflictsT = {
      {
        from = 3,
        to = 10,
        ours = {len = 2},
        theirs = {len = 3}
      }
    }
    conflicts.update_lines(conflictsT, 1, 2, 'ours', false)
    assert.are.same(conflictsT[1].from, 5)
    assert.are.same(conflictsT[1].to, 12)
    assert.are.same(conflictsT[1].ours.len, 2)
    assert.are.same(conflictsT[1].theirs.len, 3)
  end)

  it('adds lines between two conflicts', function()
    local conflictsT = {
      {
        from = 1,
        to = 5,
        ours = {len = 1},
        theirs = {len = 1}
      },
      {
        from = 8,
        to = 12,
        ours = {len = 1},
        theirs = {len = 1}
      },
    }

    conflicts.update_lines(conflictsT, 6, 7, 'ours', false)
    assert.are.same(conflictsT[1], {
      from = 1,
      to = 5,
      ours = {len = 1},
      theirs = {len = 1}
    })
    assert.are.same(conflictsT[2], {
      from = 10,
      to = 14,
      ours = {len = 1},
      theirs = {len = 1}
    })
  end)
end)
