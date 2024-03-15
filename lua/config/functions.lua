local M               = {}
local api             = vim.api
local popup           = require('plenary.popup')
local illuminate      = require('illuminate')
local previewers      = require('telescope.previewers')
local pickers         = require "telescope.pickers"
local builtin         = require 'telescope.builtin'
local finders         = require "telescope.finders"
local conf            = require("telescope.config").values
local telescope_utils = require "telescope.utils"
local actions         = require "telescope.actions"
local action_state    = require "telescope.actions.state"
local entry_display   = require "telescope.pickers.entry_display"
local statusline      = require 'config.statusline'
local utils           = require 'config.utils'

local delta_bcommits  = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', entry.value .. '^!', '--',
      entry.current_file }
  end
}

local delta           = previewers.new_termopen_previewer {
  get_command = function(entry)
    return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', entry.path }
  end
}

function SubmitRenamePopup(win_id)
  local bufnr = vim.api.nvim_win_get_buf(0)
  local val = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  ClosePopup(win_id)

  local params = vim.lsp.util.make_position_params()
  params.newName = val[1]
  vim.lsp.buf_request(0, "textDocument/rename", params)
end

function ClosePopup(win_id)
  vim.api.nvim_win_close(win_id, true)
  vim.api.nvim_input('<Esc>')
  illuminate.toggle()
end

function OpenPopup(title, val, submit)
  local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
  local ui          = vim.api.nvim_list_uis()[1]
  local height      = 1
  local width       = ui.width / 2

  local win_id      = popup.create({}, {
    title = title,
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
    -- Not implemented yet by plenary.
    callback = nil,
  })
  illuminate.toggle()

  local bufnr       = vim.api.nvim_win_get_buf(win_id)
  local keymap_opts = { silent = true, nowait = true, noremap = true }
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { val })
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'i', '<CR>', "<cmd>lua " .. submit .. "(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', "<cmd>lua ClosePopup(" .. win_id .. ")<CR>", keymap_opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'i', 'q', "<cmd>lua ClosePopup(" .. win_id .. ")<CR>", keymap_opts)
end

M.my_git_status   = function(opts)
  opts = opts or {}
  opts.previewer = delta

  builtin.git_status(opts)
end

M.my_git_commits  = function(opts)
  opts = opts or {}
  opts.previewer = {
    delta,
    previewers.git_commit_message.new(opts),
    previewers.git_commit_diff_as_was.new(opts),
  }

  builtin.git_commits(opts)
end

M.my_git_bcommits = function(opts)
  opts = opts or {}
  opts.previewer = {
    delta_bcommits,
    previewers.git_commit_message.new(opts),
    previewers.git_commit_diff_as_was.new(opts),
  }

  builtin.git_bcommits(opts)
end

function Rename()
  local win = api.nvim_get_current_win()
  local buf = api.nvim_win_get_buf(win)
  local cursor = api.nvim_win_get_cursor(win)
  local line = api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
  local cursor_pos = cursor[2] + 1
  local current_char = line:sub(cursor_pos, cursor_pos)

  if not current_char:match('[%w_-]') then
    return
  end

  local prefix = ''
  local suffix = ''

  current_char = line:sub(cursor_pos, cursor_pos)
  while current_char:match('[%w_-]') do
    prefix = current_char .. prefix
    cursor_pos = cursor_pos - 1
    current_char = line:sub(cursor_pos, cursor_pos)
  end

  cursor_pos = cursor[2] + 1 + 1
  current_char = line:sub(cursor_pos, cursor_pos)
  while current_char:match('[%w_-]') do
    suffix = suffix .. current_char
    cursor_pos = cursor_pos + 1
    current_char = line:sub(cursor_pos, cursor_pos)
  end

  local var_name = prefix .. suffix
  OpenPopup('Refactor', var_name, 'SubmitRenamePopup')
end

function M.go_to_usages()
  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = false }

  vim.lsp.buf_request_all(0, 'textDocument/references', params, function(result)
    if not result then return end

    -- LSP returns a weird hash table so extract the first and only value.
    for _, v in pairs(result) do result = v.result end

    -- Filter out all references that are part of import statements.
    -- TODO: Open files in parallel, think about using ast parsing to determine if it's an import.
    local filtered_refs = {}
    for _, ref in ipairs(result) do
      local file_path = ref.uri
      local lines = vim.fn.readfile(vim.uri_to_fname(file_path))
      if not lines[ref.range.start.line + 1]:match('^import') then
        table.insert(filtered_refs, ref)
      end
    end

    local total = 0
    for _, _ in ipairs(filtered_refs) do total = total + 1 end

    if total == 0 then return end
    if total == 1 then
      for _, ref in ipairs(filtered_refs) do
        local start = ref.range.start
        vim.api.nvim_command('edit ' .. ref.uri)
        vim.api.nvim_win_set_cursor(0, { start.line + 1, start.character })
        return
      end
    end

    local files = {}
    local items = {}
    for _, ref in ipairs(filtered_refs) do
      local item = {}
      local filename = vim.uri_to_fname(ref.uri)
      if not files[filename] then files[filename] = 1 end

      item.basename = vim.fs.basename(filename)
      item.filename = filename
      item.lnum = ref.range.start.line
      item.col = ref.range.start.character
      table.insert(items, item)
    end

    local total_files = vim.tbl_count(files)
    local results_title = total .. ' references in ' .. total_files .. ' file'
    if total_files > 1 then results_title = results_title .. 's' end

    local displayer = entry_display.create {
      separator = "",
      items = {
        { width = 1 },
        { remaining = true },
        { width = 10 },
        { width = 100 },
      },
    }

    local function make_display(entry)
      local icon, hl_group = telescope_utils.get_devicons(entry.filename, false)
      local parent = vim.fs.dirname(entry.filename)
      return displayer {
        { icon,                        hl_group },
        { ' ' .. entry.value.basename, "TelescopeResultsIdentifier" },
        { ':' .. entry.lnum,           "TelescopeResultsComment" },
        { parent,                      "TelescopeResultsComment" },
      }
    end

    pickers.new({}, {
      results_title = results_title,
      initial_mode = "normal",
      finder = finders.new_table({
        results = items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.filename,
            filename = entry.filename,
            lnum = entry.lnum + 1,
          }
        end
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.vim_buffer_vimgrep.new({}),
    }):find()
  end)
end

function M.commit()
  local last_commit = vim.fn.system('git log -1 --pretty=%B'):gsub("\n", "")
  local displayer = entry_display.create {
    separator = "",
    items = {
      { width = 1 },
      { remaining = true },
      { width = 100 },
    },
  }

  local function make_display(entry)
    local icon, hl_group = telescope_utils.get_devicons(entry.filename, false)
    local parent = vim.fs.dirname(entry.filename)
    local basename = vim.fs.basename(entry.filename)
    parent = vim.fn.fnamemodify(parent, ':~:.')

    return displayer {
      { icon,                   hl_group },
      { ' ' .. basename .. ' ', "TelescopeResultsIdentifier" },
      { parent,                 "TelescopeResultsComment" },
    }
  end

  local results = {}
  for _, file in ipairs(statusline.get_staged()) do
    local abs_path = vim.fn.fnamemodify(file, ':p')
    local file_path = vim.uri_from_fname(abs_path)
    table.insert(results, { abs_path = abs_path, file_path = file_path })
  end

  illuminate.toggle()
  pickers.new({}, {
    prompt_title = "Commit",
    prompt_prefix = "",
    default_text = last_commit,
    get_status_text = function() return "" end,
    initial_mode = "normal",
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = make_display,
          filename = entry.abs_path,
          ordinal = entry.abs_path,
        }
      end
    },
    previewer = previewers.new_termopen_previewer {
      get_command = function(entry)
        return { 'git', '-c', 'core.pager=delta', '-c', 'delta.side-by-side=false', 'diff', '--staged', entry.filename }
      end
    },
    attach_mappings = function(prompt_bufnr, map)
      map({ "i", "n" }, "<M-CR>", function()
        actions.close(prompt_bufnr)
        illuminate.toggle()
        vim.cmd('edit ' .. action_state.get_selected_entry().filename)
      end)

      actions.select_default:replace(utils.async(function()
        local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
        utils.spawn("git", { "commit", "-m", prompt })
        utils.vim_loop(function()
          actions.close(prompt_bufnr)
          illuminate.toggle()
        end)
      end))
      return true
    end,
  }):find()
  -- Set cursor to the first col.
  vim.schedule(function() vim.api.nvim_win_set_cursor(0, { 1, 0 }) end)
end

M.copy_github_link = utils.async(function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local basename = vim.fn.fnamemodify(bufname, ':t')
  local parent = vim.fs.dirname(bufname)
  local git_remote_origin = utils.spawn('git', { 'config', '--get', 'remote.origin.url' })

  parent = vim.fn.fnamemodify(parent, ':~:.')
  bufname = parent .. '/' .. basename

  if git_remote_origin == "" then return end

  local repo_url = git_remote_origin:gsub("git@github.com:", "https://github.com/")
  repo_url = repo_url:gsub("%.git", "")
  repo_url = repo_url:gsub("\n", "")

  utils.vim_loop(function()
    local vstart = vim.fn.getpos('v')[2]
    local vend = vim.fn.getpos('.')[2]
    vim.fn.setreg('*', string.format("%s/blob/main/%s#L%d-L%d", repo_url, bufname, vstart, vend))
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
  end)
end)

return M
