local conflicts = require('config.conflicts')
local tmp_file = '/tmp/conflicts.txt'
local eq = assert.are.same

local function parse(content)
  local lines = {}
  for line in content:gmatch('[^\r\n]+') do
    table.insert(lines, line)
  end
  return conflicts.parse(lines)
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
      original_from = 2,
      original_to = 6,
      to = 2,
      ours = { len = 1 },
      theirs = { len = 1 }
    } }
    eq(expectedConflict, parsedConflict)
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
    eq(2, #parsedConflicts)
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
    local expectedConflict = { {
      from = 3,
      original_from = 3,
      original_to = 9,
      to = 4,
      ours = { len = 2 },
      theirs = { len = 2 }
    } }
    eq(expectedConflict, conflicts)
  end)

  it('should return empty table when no conflicts are found', function()
    local expectedConflicts = parse([[
  This is some text.
  This is some text.
  This is some text.
  ]])
    eq({}, expectedConflicts)
  end)

  it('should return empty table when file is empty', function()
    eq({}, parse(''))
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
    local expectedConflict = { {
      from = 2,
      original_from = 2,
      original_to = 8,
      to = 3,
      ours = { len = 2 },
      theirs = { len = 2 }
    }, {
      from = 5,
      original_from = 10,
      original_to = 16,
      to = 6,
      ours = { len = 2 },
      theirs = { len = 2 }
    } }
    eq(expectedConflict, expectedConflicts)
  end)

  it('should parse a conflict with multiple lines and multiple conflicts and different conflict lengths', function()
    local expectedConflicts = parse([[
This is some text.
<<<<<<< HEAD
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
>>>>>>> branch-name
This is the end of the file.
]])
    local expectedConflict = { {
      from = 2,
      original_from = 2,
      original_to = 7,
      to = 3,
      ours = { len = 1 },
      theirs = { len = 2 }
    }, {
      from = 5,
      original_from = 9,
      original_to = 14,
      to = 6,
      ours = { len = 2 },
      theirs = { len = 1 }
    } }
    eq(expectedConflict, expectedConflicts)
  end)

  it('should parse conflict when at the beginning of the file', function()
    local expected_conflicts = parse([[
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
This is some more text.
]])
    local expectedConflict = { {
      from = 1,
      original_from = 1,
      original_to = 5,
      to = 1,
      ours = { len = 1 },
      theirs = { len = 1 }
    } }
    eq(expectedConflict, expected_conflicts)
  end)

  it('should parse conflict when at the end of the file', function()
    local expected_conflicts = parse([[
This is some text.
<<<<<<< HEAD
This is some text from our branch.
=======
This is some text from their branch.
>>>>>>> branch-name
]])
    local expectedConflict = { {
      from = 2,
      original_from = 2,
      original_to = 6,
      to = 2,
      ours = { len = 1 },
      theirs = { len = 1 }
    } }
    eq(expectedConflict, expected_conflicts)
  end)
end)

describe('File content generator #content', function()
  it('creates proper file contents for both sides', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      'This is some text from our branch.',
      '=======',
      'This is some text from their branch.',
      '>>>>>>> branch-name',
      'This is some more text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      'This is some text from our branch.',
      'This is some more text.'
    }, content.ours)
    eq({
      'This is some text.',
      'This is some text from their branch.',
      'This is some more text.'
    }, content.theirs)
  end)

  it('creates proper file contents for both sides with multiple conflicts', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      'This is some text from our branch.',
      '=======',
      'This is some text from their branch.',
      '>>>>>>> branch-name',
      'This is some more text.',
      '<<<<<<< HEAD',
      'This is some additional text from our branch.',
      '=======',
      'This is some additional text from their branch.',
      '>>>>>>> branch-name',
      'This is the end of the file.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      'This is some text from our branch.',
      'This is some more text.',
      'This is some additional text from our branch.',
      'This is the end of the file.'
    }, content.ours)
    eq({
      'This is some text.',
      'This is some text from their branch.',
      'This is some more text.',
      'This is some additional text from their branch.',
      'This is the end of the file.'
    }, content.theirs)
  end)

  it('creates proper file contents when there are no conflicts', function()
    local lines           = {
      'This is some text.',
      'This is some text.',
      'This is some text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq(lines, content.ours)
    eq(lines, content.theirs)
  end)

  it('handles variable length conflicts - ours is longer', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      'This is some text from our branch.',
      'This is some text from our branch.',
      '=======',
      'This is some text from their branch.',
      '>>>>>>> branch-name',
      'This is some more text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      'This is some text from our branch.',
      'This is some text from our branch.',
      'This is some more text.',
    }, content.ours)
    eq({
      'This is some text.',
      'This is some text from their branch.',
      '',
      'This is some more text.',
    }, content.theirs)
  end)

  it('handles variable length conflicts - theirs is longer', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      'This is some text from our branch.',
      '=======',
      'This is some text from their branch.',
      'This is some text from their branch.',
      '>>>>>>> branch-name',
      'This is some more text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      'This is some text from our branch.',
      '',
      'This is some more text.',
    }, content.ours)
    eq({
      'This is some text.',
      'This is some text from their branch.',
      'This is some text from their branch.',
      'This is some more text.',
    }, content.theirs)
  end)

  it('handles no theirs conflict', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      'This is some text from our branch.',
      '=======',
      '>>>>>>> branch-name',
      'This is some more text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      'This is some text from our branch.',
      'This is some more text.',
    }, content.ours)
    eq({
      'This is some text.',
      '',
      'This is some more text.',
    }, content.theirs)
  end)

  it('handles no ours conflict', function()
    local lines           = {
      'This is some text.',
      '<<<<<<< HEAD',
      '=======',
      'This is some text from their branch.',
      '>>>>>>> branch-name',
      'This is some more text.'
    }
    local parsedConflicts = parse(table.concat(lines, '\n'))
    local content         = conflicts.get_file_content(lines, parsedConflicts)
    eq({
      'This is some text.',
      '',
      'This is some more text.',
    }, content.ours)
    eq({
      'This is some text.',
      'This is some text from their branch.',
      'This is some more text.',
    }, content.theirs)
  end)
end)
