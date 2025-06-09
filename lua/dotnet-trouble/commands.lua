local M = {}

vim.api.nvim_create_user_command("DotnetTroubleLog", function()
    require("dotnet-trouble.log"):Print()
end, {})

return M
