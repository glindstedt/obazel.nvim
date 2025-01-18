---@mod obazel-nvim.health

local check = require("obazel.config.check")
local config = require("obazel.config")

local health = {}

--- Checks plugin health using vim.health
function health.check()
    vim.health.start("obazel")

    local ok, err = check.validate(config)
    if ok then
        vim.health.ok("Ok.")
    else
        vim.health.error("" .. err)
    end
    -- TODO unrecognized keys
end

return health
