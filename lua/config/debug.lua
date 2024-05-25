local utils = require("config.utils")

local M = {}

M.setup_debug = utils.async(function()
  require("dap-vscode-js").setup({
    debugger_path = vim.fn.stdpath('data') .. "/lazy/vscode-js-debug",
    adapters = { 'chrome', 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost', 'node', 'chrome' },
  })
  local js_based_languages = { "typescript", "javascript", "typescriptreact" }
  local dap = require("dap")

  for _, language in ipairs(js_based_languages) do
    dap.configurations[language] = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require 'dap.utils'.pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-chrome",
        request = "launch",
        name = "Start Chrome with \"localhost\"",
        url = "http://localhost:3000",
        webRoot = "${workspaceFolder}",
        userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir"
      },
      -- TODO: Remove once VSC launch JSON works.
      {
        name = "Debug Vitest Tests",
        type = "pwa-node",
        runtimeExecutable = "node",
        request = "launch",
        program = "node_modules/vitest/vitest.mjs",
        protocol = "inspector",
        args = { "run", "${file}", },
        cwd = "${workspaceFolder}/ui",
        resolveSourceMapLocations = {
          "${workspaceFolder}/**",
          "!**/node_modules/**"
        }
      }
    }
  end

  local launch_json, err = utils.read_file(vim.fn.getcwd() .. "/.vscode/launch.json")
  if err or launch_json == nil then return end

  local lines = {}

  -- Remove // comments and empty lines.
  for s in launch_json:gmatch("[^\r\n]+") do
    local trimmed = s:gsub("%s+", "")
    if trimmed ~= "" and trimmed:sub(1, 2) ~= "//" then
      table.insert(lines, s)
    end
  end
  -- Remove trailing commas.
  for i, line in ipairs(lines) do
    local trimmed_next = lines[i + 1] and lines[i + 1]:gsub("%s+", "") or ""
    -- If line ends with a comma and the next line is a closing bracket, remove the comma.
    if line:sub(-1) == "," and (trimmed_next:sub(1, 1) == "}" or trimmed_next:sub(1, 1) == "]") then
      lines[i] = line:sub(1, -2)
    end
  end

  for _, conf in ipairs(vim.json.decode(table.concat(lines, "\n")).configurations) do
    if conf.type == 'node' then
      conf.type = 'pwa-node'
      for _, language in ipairs(js_based_languages) do
        table.insert(dap.configurations[language], 1, conf) -- Put before default configurations.
      end
    end

    local curr = dap.configurations[conf.type]
    if curr == nil then
      dap.configurations[conf.type] = { conf }
    else
      table.insert(curr, conf)
    end
  end
end)

return M
