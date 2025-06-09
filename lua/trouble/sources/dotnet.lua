---@diagnostic disable: inject-field

---@type trouble.Source
local M = {}

-- M.highlights = {
--   Message = "TroubleText",
--   ItemSource = "TroubleText",
--   Code = "TroubleCode",
-- }

---@diagnostic disable-next-line: missing-fields
M.config = {
  -- formatters = {
  --   -- dotnet_icon = function(ctx)
  --   --   return {
  --   --     text = require("mini.icons").filetype_icons.cs,
  --   --     --TODO: change hl group
  --   --     hl = "TodoFg" .. ctx.item.tag,
  --   --   }
  --   -- end,
  -- },
  modes = {
    dotnet = {
      events = { "BufWritePost" },
      source = "dotnet",
      groups = {
        -- { "tag", format = "{dotnet_icon} {tag}" },
        { "directory" },
        -- { "filename", format = "{file_icon} {basename} {count}" },
        { "filename", format = "{file_icon} {item.filename} {count}" },
      },
      -- sort = { "severity", "filename", "pos", "message" },
      format = "{severity_icon} {message:md} {item.source} {code} {pos}",
    },
  },
}

local log = require("dotnet-trouble.log")
local executor_factory = require("dotnet-trouble.executor")

function M.get(cb, ctx)
      local build_file = require("dotnet-trouble.dotnet_commands").GetBuildFile(ctx.main.buf)

      if not build_file then
        log:Debug("Unable to process buffer " .. ctx.main.buf)
        return
      end

      local executor = executor_factory:Get(build_file)

      cb(executor.results:GetTroubleItems())
end

return M
