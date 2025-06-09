local dotnet = require("dotnet-trouble.dotnet_commands")
local log = require("dotnet-trouble.log")

---@class dotnet-trouble.Executor
---@field results dotnet-trouble.Result.Store
---@field private build_file string
---@field private _running boolean
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
  }

  ---@type dotnet-trouble.Executor
  local instance = setmetatable(data, Executor)

  -- instance:InitWorker()

  return instance
end

-- ---@private
-- function Executor:InitWorker()
--   log:Trace("Instantiating executor worker")
--
--   if self._worker then
--     log:Warning("Executor already has a worker")
--     return
--   end
--
--   local process = function(build_file)
--     -- local _log = require("dotnet-trouble.log")
--     -- _log:Debug("Running build for: " .. build_file)
--
--     local _dotnet = require("dotnet-trouble.dotnet_commands")
--
--     local build_cmd = _dotnet.Build(build_file)
--     local build_result = build_cmd:wait()
--
--     -- _log:Debug("Dotnet build finished with exit code - " .. build_result.code)
--
--     return build_result.stdout
--   end
--
--   local afterProcess = function(...)
--     log:Trace("Processing worker results")
--
--     local results = self:ProcessResult(...)
--
--     log:Trace("Finished processing worker results")
--
--     print("finished")
--     return results
--   end
--
--   self._worker = vim.uv.new_work(process, afterProcess)
--
--   log:Trace("Worker instantiating")
-- end

function Executor:Run()
  log:Trace("Run request received for executor")

  if self._running == true then
    log:Trace("Executor is already running")
    return
  end

  self._running = true

  log:Trace("Running executor")

  dotnet.Build(self.build_file, function (out)
        log:Debug("Dotnet build finished with exit code - " .. out.code)

        -- if out.code ~= 0 then
        --     return
        -- end

        self:ProcessResult(out.stdout)
  end)
end

---@private
---@param stdout string
function Executor:ProcessResult(stdout)
  if not stdout then
    log:Error("Did not get a result back from the dotnet build")
  end

  for line in stdout:gmatch("[^\r\n]+") do
    self.results:Add(line)
  end

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
