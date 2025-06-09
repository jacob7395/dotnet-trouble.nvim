local executor_factory = require("dotnet-trouble.executor")

---@class dotnet-trouble
local M = {}

local log = require("dotnet-trouble.log")

local function RunExecutor(buffer)
  local build_file = require("dotnet-trouble.dotnet_commands").GetBuildFile(buffer)

  log:Trace("Identified build file starting executor")

  if not build_file then
    log:Debug("Unable to process buffer " .. buffer)
    return
  end

  local executor = executor_factory:Get(build_file)

  log:Trace("Retrieved executor for build file")

  executor:Run()
end

---@param config? DotnetTroubleConfig
function M.setup(config)
  --TODO: Check for trouble dependency
  if vim.fn.has("nvim-0.11") == 0 then
    return vim.notify("roslyn.nvim requires at least nvim 0.11", vim.log.levels.WARN, { title = "donnet-trouble.nvim" })
  end

  local group = vim.api.nvim_create_augroup("dotnet-trouble.nvim", { clear = true })

  require("dotnet-trouble.config").setup(config)

  -- vim.api.nvim_create_autocmd("FileType", {
  --     group = group,
  --     pattern = "cs",
  --     callback = function()
  --         -- require("roslyn.commands").create_roslyn_commands()
  --     end,
  -- })

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = group,
    pattern = { "*.cs" },
    callback = function(args)
      local ok, _ = pcall(RunExecutor, args.buf)

      if ok == false then
        vim.notify_once("Unexpected error occurred when running dotnet-trouble for buffer: " .. args.buf)
        return
      end

      vim.notify_once("dotnet-trouble started")
    end,
  })

  require("dotnet-trouble.commands")
end

return M
