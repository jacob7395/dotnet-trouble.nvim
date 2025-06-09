local M = {}

local config = require("dotnet-trouble.config").get()
local output_path = config.build_output_path

local cache = require("dotnet-trouble.cache")

local log = require("dotnet-trouble.log")

---@return string[]
local function buildCommandArgs(command, build_file)
  return { "dotnet", command, "-o", output_path, build_file }
end

function M.GetBuildFile(buffer)
  local build_file = cache.Get("build_file", buffer)
  if build_file then
    log:Debug("Buffer " .. buffer .. " build file had cached value " .. build_file)
    return build_file
  end

  local path = vim.api.nvim_buf_get_name(buffer)
  log:Debug("File Path: " .. path .. "\n")

  local dir = vim.fn.fnamemodify(path, ":h")

  local dotnet_file = vim.fs.find(function(name)
    --TODO: add option to build .sln (with config default)
    return name:match(".*%.csproj$")
  end, { limit = 1, type = "file", path = dir, upward = true })

  if #dotnet_file == 0 then
    log:Debug("No dotnet sln or csproj found in dir or parent dirs" .. "\n")
    return nil
  end

  log:Debug("Build file identified as " .. dotnet_file[1] .. " for buffer " .. buffer)
  return cache.Set("build_file", buffer, dotnet_file[1])
end

---@return vim.SystemObj Object
function M.Clean(build_file)
  return vim.system(buildCommandArgs("clean", build_file))
end

--- @param callback fun(out: vim.SystemCompleted)
function M.Build(build_file, callback)
  vim.system(buildCommandArgs("build", build_file), { text = true }, callback)
end

return M
