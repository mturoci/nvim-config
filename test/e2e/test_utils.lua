local M = {}

M.open_file = function(nvim, path)
  vim.fn.rpcrequest(nvim, 'nvim_command', 'edit ' .. path)
  -- Add sleep to wait for autocmds to be registered properly.
  vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
end

M.get_current_line = function(nvim)
  if not nvim then error('nvim is not initialized') end

  vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 1m')
  return vim.fn.rpcrequest(nvim, 'nvim_eval', 'line(".")')
end

M.accept_conflict = function(nvim)
  if not nvim then error('nvim is not initialized') end

  local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
  vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'a', true, false, true), 'm',
    true)

  -- Add sleep to wait for the command to finish.
  vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
end

M.accept_both_conflicts = function(nvim)
  if not nvim then error('nvim is not initialized') end

  local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
  vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'b', true, false, true), 'm',
    true)

  -- Add sleep to wait for the command to finish.
  vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
end

return M
