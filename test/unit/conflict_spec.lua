local conflicts = require('config.conflicts')
local tmp_file = '/tmp/conflicts.txt'

function parse(content)
  local file = io.open(tmp_file, "w")
  if file then
      file:write(content)
      file:close()
  else
      error("Could not open file for writing.")
  end
  return conflicts.parse(tmp_file)
end

describe('Conflicts', function()
local conflicts = require('config.conflicts')
  
  after_each(function()
    if conflicts.file_exists(tmp_file) then
      assert(os.remove(tmp_file))
    end
  end)

  it('should parse a single conflict', function()
    local conflicts = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
This is some more text.
  ]])
    local expectedConflict = {{
        from = 2,
        to = 6,
        ours = {from = 2, to = 3},
        theirs = {from = 5, to = 6}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)

  it('should parse multiple conflicts', function()
    local conflicts = parse([[
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
    assert.is.equal(2, #conflicts)
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
        ours = {from = 3, to = 5},
        theirs = {from = 7, to = 9}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)

  it('should return empty table when no conflicts are found', function()
    local conflicts = parse([[
This is some text.
This is some text.
This is some text.
]])
    assert.is.same({}, conflicts)
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
    local conflicts = parse([[
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
        ours = {from = 2, to = 4},
        theirs = {from = 6, to = 8}
    }, {
        from = 10,
        to = 16,
        ours = {from = 10, to = 12},
        theirs = {from = 14, to = 16}
    }}
    assert.is.same(expectedConflict, conflicts)
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
        ours = {from = 1, to = 2},
        theirs = {from = 4, to = 5}
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
        ours = {from = 2, to = 3},
        theirs = {from = 5, to = 6}
    }}
    assert.is.same(expectedConflict, conflicts)
  end)

end)
