local dotnet = require("dotnet-trouble.dotnet_commands")
local log = require("dotnet-trouble.log")

---@class dotnet-trouble.Executor
---@field results dotnet-trouble.Result.Store
---@field private build_file string
---@field private _running boolean
---@field has_executed boolean
local Executor = {}
Executor.__index = Executor

---@param build_file string
---@return dotnet-trouble.Executor
function Executor.new(build_file)
  log:Debug("Building new executor for: " .. build_file)

  local data = {
    results = require("dotnet-trouble.results").new(build_file),
    _running = false,
    build_file = build_file,
    has_executed = false,
  }

  return setmetatable(data, Executor)
end

function Executor:OnBuffWrite()
  self:Run()
end

function Executor:OnBuffEnter()
  if not Executor.has_executed then
    self:Run()
    log:Info("Executor for " .. self.build_file .. " started runniny")
  end
end

function Executor:Run()
  log:Trace("Run request received for executor")

  self.has_executed = true

  if self._running == true then
    log:Trace("Executor is already running")
    return
  end

  self._running = true

  log:Trace("Running executor")

  dotnet.Build(self.build_file, function(out)
    log:Debug("Dotnet build finished with exit code - " .. out.code)

    -- if out.code ~= 0 then
    --     return
    -- end

    self:ProcessResult(out.stdout)

    local success, _ = pcall(require, "trouble")

    if success then
      vim.schedule(function()
        vim.cmd("Trouble dotnet refresh")
      end)
    end
  end)
end

---@private
---@param stdout string
function Executor:ProcessResult(stdout)
  if not stdout then
    log:Error("Did not get a result back from the dotnet build")
  end

  local results = {}

  for line in stdout:gmatch("[^\r\n]+") do
    log:Debug(stdout)

    if not (line:match("error") or line:match("warning")) then
      goto continue
    end

    results[#results + 1] = self.results:Parse(line)
    ::continue::
  end

  self.results:Set(results)
  self._running = false
end

-- ---@private
-- ---@return string
-- function Executor.RunBuildInternae(build_file)
--   local _log = require("dotnet-trouble.log")
--   _log:Debug("Running build for: " .. build_file)
--
--   local build_cmd = dotnet.Build(build_file)
--   local build_result = build_cmd:wait()
--
--   _log:Debug("Dotnet build finished with exit code - " .. build_result.code)
--
--   return build_result.stdout
-- end

---@class dotnet-trouble.Executor.Factory
---@field private Executors table<string, dotnet-trouble.Executor>
local Factory = {
  Executors = {},
}

---@return dotnet-trouble.Executor
function Factory:Get(build_file)
  log:Debug("Getting executor for: " .. build_file)

  if self.Executors[build_file] then
    log:Trace("executor is cached")
    return self.Executors[build_file]
  end

  log:Trace("Executor not cached")

  self.Executors[build_file] = Executor.new(build_file)

  log:Trace("Created and cached executor")

  return self.Executors[build_file]
end

return Factory
