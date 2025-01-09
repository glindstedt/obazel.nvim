local check = require("obazel.config.check")
local config = require("obazel.config")

local health = {}

function health.check()
    vim.health.start("obazel")

    local ok, err = check.validate(config)
    if ok then
        vim.health.ok("Ok.")
    else
        vim.health.error("" .. err)
    end
end

return health
