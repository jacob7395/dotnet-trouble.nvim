---@diagnostic disable: inject-field

local Item = require("trouble.item")

---@type trouble.Source
local M = {}

M.highlights = {
  Message = "TroubleText",
  ItemSource = "Comment",
  Code = "Comment",
}

---@diagnostic disable-next-line: missing-fields
M.config = {
  formatters = {
    -- dotnet_icon = function(ctx)
    --   return {
    --     text = require("mini.icons").filetype_icons.cs,
    --     --TODO: change hl group
    --     hl = "TodoFg" .. ctx.item.tag,
    --   }
    -- end,
  },
  modes = {
    dotnet = {
      events = { "BufWritePost" },
      source = "dotnet",
      groups = {
        -- { "tag", format = "{dotnet_icon} {tag}" },
        { "directory" },
        { "filename", format = "{file_icon} {basename} {count}" },
      },
      sort = { "severity", "filename", "pos", "message" },
      format = "{severity_icon} {message:md} {item.source} {code} {pos}",
    },
  },
}

local function BuildItem(line)
 
  local split = vim.split(line, ":")
  local filepath, level_code, message_proj = split[1], split[2], split[3]

  split = vim.split(filepath, "[(,)]")
  local filePath, row, col = split[1], tonumber(split[2]), tonumber(split[3])

  split = vim.split(level_code, "[ ]", { trimempty = true })
  local level, code = split[1], split[2]

  local message = message_proj

  local index = message_proj:find("%[")

  if index and index > 1 then
    message = message_proj:sub(1, index - 1)
  end

  local severity

  if level_code == "error" then
    severity = vim.diagnostic.severity.ERROR
  else
    severity = vim.diagnostic.severity.WARN
  end

    return Item.new({
        buf = vim.fn.bufadd(filePath),
        filename = vim.fn.fnamemodify(filePath, ":t"),
        pos = { row, col },
        -- end_pos = { row and (row + 1) or nil, col },
        source = "dotnet build",
        item = {
            directory = vim.fn.fnamemodify(filePath, ":h"),
            severity = severity,
            code = code,
            message = message,
            }
      })

end

---@type table<number, string?>
local cs_proj_cache = {}

local function GetBuildFile(buffer)
  if cs_proj_cache[buffer] then
    return "Buffer(" .. buffer .. ") build file cached - " .. cs_proj_cache[buffer] .. "\n", cs_proj_cache[buffer]
  end

  local debugInfo = ""

  local path = vim.api.nvim_buf_get_name(buffer)
  debugInfo = debugInfo .. "File Path: " .. path .. "\n"

  local dir = vim.fn.fnamemodify(path, ":h")

  local dotnet_file = vim.fs.find(function(name)
    return name:match(".*%.csproj$")
  end, { limit = 1, type = "file", path = dir, upward = true })

  if #dotnet_file == 0 then
    debugInfo = debugInfo .. "No dotnet sln or csproj found in dir or parent dirs" .. "\n"
    return debugInfo, nil
  end

  cs_proj_cache[buffer] = dotnet_file[1]
  return debugInfo .. cs_proj_cache[buffer], cs_proj_cache[buffer]
end

---@type table<number, trouble.Item[]>
local cache = {}

-- function M.setup()
--   vim.api.nvim_create_autocmd("BufWritePost", {
--
--     group = vim.api.nvim_create_augroup("trouble.dotnet.filechange", { clear = true }),
--     pattern = { "*.cs" },
--     callback = function(event)
--       -- since multiple namespaces exist and we can't tell which namespace the
--       -- diagnostics are from.
--       cache[event.buf] = vim.tbl_map(M.item, vim.diagnostic.get(event.buf))
--       cache[0] = nil
--     end,
--   })
--
--   for _, diag in ipairs(vim.diagnostic.get()) do
--     local buf = diag.bufnr
--     if buf and vim.api.nvim_buf_is_valid(buf) then
--       cache[buf] = cache[buf] or {}
--
--       table.insert(cache[buf], M.item(diag))
--       Item.add_id(cache[buf], { "item.source", "severity", "code" })
--     end
--   end
-- end

local function ProcessBuffer(buffer)
  local items = {} ---@type trouble.Item[]

  local debugInfo, build_file = GetBuildFile(buffer)

  if not build_file then
    vim.notify(debugInfo, vim.log.levels.DEBUG, { title = "Dotnet Trouble Source Run" })
    return items
  end

  debugInfo = debugInfo .. "Dotnet Build File: " .. build_file .. "\n"

  local output_path = vim.fs.joinpath(vim.fn.stdpath("run"), "dotnet-trouble")
  
   local dir_cleanup = vim.fn.delete(output_path, "rf")
   debugInfo = debugInfo .. "Cleaned up output dir: " .. dir_cleanup .. "\n"
 
  local clean_command = "dotnet clean -o " .. output_path .. " " .. build_file
  local build_command = "dotnet build -o " .. output_path .. " " .. build_file

   debugInfo = debugInfo .. "Running dotnet build command - " .. build_command .. "\n"

  local _ = vim.system(vim.split(clean_command, ' ', { trimempty = true }))
  local build_result = vim.fn.system(build_command)

  debugInfo = debugInfo .. "Dotnet Build finished\nChecking for build issues\n"

  local processedLines = {}

  for line in build_result:gmatch("[^\r\n]+") do
    if not (line:match("error") or line:match("warning")) then
        goto continue
    end
      local lineHash = vim.fn.sha256(line)

      if processedLines[lineHash] then
        debugInfo = debugInfo .. "Duplicated Line Detected: \n" .. line .. "\n"
        goto continue
      end

      processedLines[lineHash] = true

      local item = BuildItem(line)

      items[#items + 1] = item

      -- debugInfo = debugInfo .. item.filename .. " (" .. item.item.severity .. ") " .. item.message .. "\n"
    ::continue::
  end

  vim.notify(debugInfo, vim.log.levels.DEBUG, { title = "Dotnet Trouble Source Run" })
  return items
end

function M.get(cb, ctx)
  cb(ProcessBuffer(ctx.main.buf))
end

return M
