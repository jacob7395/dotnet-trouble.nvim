local executor_factory = require("dotnet-trouble.executor")

---@class dotnet-trouble
local M = {}

local log = require("dotnet-trouble.log")

local function GetExecutor(buffer)
  local build_file = require("dotnet-trouble.dotnet_commands").GetBuildFile(buffer)

  log:Trace("Identified build file starting executor")

  if not build_file then
    log:Debug("Unable to process buffer " .. buffer)
    return nil
  end

  return executor_factory:Get(build_file)
end

---@param config? DotnetTroubleConfig
function M.setup(config)
  --TODO: Check for trouble dependency
  if vim.fn.has("nvim-0.11") == 0 then
    return vim.notify("roslyn.nvim requires at least nvim 0.11", vim.log.levels.WARN, { title = "donnet-trouble.nvim" })
  end

  local group = vim.api.nvim_create_augroup("dotnet-trouble.nvim", { clear = true })

  require("dotnet-trouble.config").setup(config)

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = { "*.cs" },
    callback = function(args)
      local ok, executor = pcall(GetExecutor, args.buf)

      if ok == false or executor == nil then
        vim.notify_once("Unexpected error occurred when running dotnet-trouble for buffer: " .. args.buf)
        return
      end

      ok, _ = pcall(executor.OnBuffWrite, executor)

      if ok == false then
        --TODO: don't notify write improve log/healthchecck/status
        vim.notify_once("Unexpected error occurred when running executor: " .. args.buf)
        return
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    group = group,
    pattern = { "*.cs" },
    callback = function(args)
      local ok, executor = pcall(GetExecutor, args.buf)

      if ok == false or executor == nil then
        vim.notify_once("Unexpected error occurred when running dotnet-trouble for buffer: " .. args.buf)
        return
      end

      pcall(executor.OnBuffEnter, executor)

      if ok == false then
        --TODO: don't notify write improve log/healthchecck/status
        vim.notify_once("Unexpected error occurred when running executor: " .. args.buf)
        return
      end
    end,
  })

  require("dotnet-trouble.commands")
end

return M
