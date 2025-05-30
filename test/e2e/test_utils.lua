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


return M
