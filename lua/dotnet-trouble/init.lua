---@class dotnet-trouble
local M = {}

---@param config? DotnetTroubleConfig
function M.setup(config)
    vim.notify("setup called")
    --TODO: Check for trouble dependency
    if vim.fn.has("nvim-0.11") == 0 then
        return vim.notify("roslyn.nvim requires at least nvim 0.11", vim.log.levels.WARN, { title = "donnet-trouble.nvim" })
    end

    local group = vim.api.nvim_create_augroup("dotnet-trouble.nvim", { clear = true })

    require("dotnet-trouble.config").setup(config)

    vim.lsp.enable("roslyn")

    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "cs",
        callback = function()
            -- require("roslyn.commands").create_roslyn_commands()
        end,
    })

    vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
        group = group,
        pattern = "cs",
       callback = function(args)

        end,
    })
end

return M
