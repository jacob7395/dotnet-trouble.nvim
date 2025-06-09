local Item = require("trouble.item")

---@class dotnet-trouble.Result.Factory
local M = {}

---@class dotnet-trouble.Result.Data
---@field build_file string Path to the build file (.sln, .csproj) this result came from
---@field filepath string The fill path of the file from root ('/')
---@field filename string The file name (no path) where this result came from
---@field directory string The directory (no file name) for the file the result came from
---@field code string
---@field severity integer
---@field row number
---@field col number
---@field raw_line string

---@class dotnet-trouble.Result: dotnet-trouble.Result.Data
---@field item trouble.Item?
---@field build_item
local Result = {}

---@param data dotnet-trouble.Result.Data
function Result.New(data)
  local item = function ()
    return Item.new({
    buf = vim.fn.bufadd(data.filepath),
    --NOTE: needs to be the full file name
    filename = data.filepath,
    pos = { data.row, data.col },
    dirname = data.directory,
    source = "dotnet",
    item = data,
  })
  end

  local result = vim.tbl_extend("force", {}, data, { build_item = item })

  return setmetatable(result, Result)
end

---@class dotnet-trouble.Result.Store
---@field data table<string, dotnet-trouble.Result>
---@field private log dotnet-trouble.Logger
---@field private build_file string
---@field private size integer
local C = {}
C.__index = C

function C:Add(log_line)
  self.log:Debug("---------------------------------------")
  self.log:Debug("Parceing line")
  self.log:Debug(log_line)


  if not (log_line:match("error") or log_line:match("warning")) then
    self.log:Debug("Line dose not contain error or warning, ignoring")
    return
  end

  -- local lineHash = vim.fn.sha256(log_line)

  -- if self.data[log_line] then
  --   self.log:Debug("Line with same hash already parsed")
  --   return
  -- end

  self.data[self.size + 1] = self:Parse(log_line)
  self.size = self.size + 1
end

---@return trouble.Item[]
function C:GetTroubleItems()
  local items = {}
  local item_hash = {}
  local unique_items = {}

  for index, value in pairs(self.data) do
    self.log:Debug("Getting trouble item " .. index)
    self.log:Debug(value.raw_line or "not set")

    local hash = vim.fn.sha256(value.raw_line)

    if item_hash[hash] then
        self.log:Debug("Duplicate item hash")
        goto continue
    end

    self.log:Debug("New item identified")

    item_hash[hash] = true

    value.item = value.item or value.build_item()

    unique_items[#unique_items + 1] = value
    items[#items+1] = value.item

    ::continue::
  end

    self.data = unique_items

  return items
end

---@private
---@return dotnet-trouble.Result
function C:Parse(log_line)
  self.log:Debug("Parsing the line")

  local split = vim.split(log_line, ":")
  local filepath_and_pos, level_code, message_proj = split[1], split[2], split[3]

  split = vim.split(filepath_and_pos, "[(,)]")
  local filePath, row, col = split[1], tonumber(split[2]), tonumber(split[3])

  if row == nil or col == nil then
    self.log:Debug("Unable to parse position setting to (1,1)\n" .. filepath_and_pos)
    row = 1
    col = 1
  end

  split = vim.split(level_code, "[ ]", { trimempty = true })
  local level, code = split[1], split[2]

  local message = message_proj

  local index = message_proj:find("%[")

  if index and index > 1 then
    message = message_proj:sub(1, index - 1)
  end

  local severity

  if level:match("error") then
    severity = vim.diagnostic.severity.ERROR
  else
    severity = vim.diagnostic.severity.WARN
  end

  self.log:Debug("Finished parsing line")

  return Result.New({
    build_file = self.build_file,
    filepath = filePath,
    filename = vim.fn.fnamemodify(filePath, ":t"),
    directory = vim.fn.fnamemodify(filePath, ":h"),
    severity = severity,
    code = code,
    message = message,
    row = row,
    col = col,
    raw_line = log_line
  })
end

---@param build_file string
---@return dotnet-trouble.Result.Store
function M.new(build_file)
  return setmetatable({ data = {}, build_file = build_file, size = 0, log = require("dotnet-trouble.log") }, C)
end

return M
