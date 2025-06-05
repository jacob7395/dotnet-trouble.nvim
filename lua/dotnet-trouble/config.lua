local M = {}

---@class DotnetTroubleConfig
---@field log_level? vim.log.levels

---@type DotnetTroubleConfig
local dotnet_trouble_config = {
    log_level = vim.log.levels.DEBUG,
}

function M.get()
    return dotnet_trouble_config
end

---@param user_config? DotnetTroubleConfig
---@return DotnetTroubleConfig
function M.setup(user_config)
    dotnet_trouble_config = vim.tbl_deep_extend("force", dotnet_trouble_config, user_config or {})

    return dotnet_trouble_config
end

return M
