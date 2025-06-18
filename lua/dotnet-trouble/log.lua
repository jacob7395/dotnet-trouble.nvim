---@class dotnet-trouble.LogMessage
---@filed time_stamp string
---@field level vim.log.levels
---@field message string

---@return dotnet-trouble.LogMessage
local function NewLog(message, level)
  return {
    time_stamp = os.date("%x", os.time()),
    level = level,
    message = message,
  }
end

local NotificationTital = "Dotnet Trouble"

---@class dotnet-trouble.Logger
local M = {}

M.size = 0
M.logs = {}

---@params message string
---@params level vim.log.levels
function M:__AddMessage(message, level)
    self.size = self.size + 1
    self.logs[self.size] = NewLog(message, level)
end

---@params message string
function M:Trace(message)
    M:__AddMessage(message, vim.log.levels.TRACE)
end

---@params message string
function M:Debug(message)
    M:__AddMessage(message, vim.log.levels.DEBUG)
end

---@params message string
function M:Info(message)
    M:__AddMessage(message, vim.log.levels.INFO)
end

---@params message string
function M:Warning(message)
    M:__AddMessage(message, vim.log.levels.WARN)
end

---@params message string
function M:Error(message)
    M:__AddMessage(message, vim.log.levels.ERROR)
end

function M:Print()
    local message = ""

    for _, log in ipairs(self.logs) do
        message = message .. log.time_stamp .. " [" .. log.level .. "]: " .. log.message .. '\n'
    end

    vim.notify(message, vim.log.levels.INFO, { tital = NotificationTital })
end

return M

-- local logs = setmetatable({}, M)
-- return M
