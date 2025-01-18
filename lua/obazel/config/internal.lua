---@mod obazel-nvim.config.internal

local check = require("obazel.config.check")

---@class obazel.InternalConfig
local default_config = {
    ---@type string
    bazel_binary = "bazel",
    ---@class obazel.InternalOverseerConfig
    overseer = {
        ---@type obazel.TemplateConfig[]
        templates = {},
        ---@type obazel.GeneratorConfig[]
        generators = {},
    },
    ---@class obazel.ConfigDebugInfo
    debug_info = {
        ---@type string[]
        unrecognized_configs = {},
    },
}

local user_config = type(vim.g.obazel) == "function" and vim.g.obazel() or vim.g.obazel or {}

---@type obazel.InternalConfig
local config = vim.tbl_deep_extend("force", default_config, user_config, {
    debug_info = {
        unrecognized_configs = check.get_unrecognized_keys(user_config, default_config),
    },
})

if #config.debug_info.unrecognized_configs > 0 then
    vim.notify(
        "unrecognized configs found in vim.g.obazel: " .. vim.inspect(config.debug_info.unrecognized_configs),
        vim.log.levels.ERROR
    )
end

local ok, err = check.validate(config)
if not ok then
    vim.notify("obazel: " .. err, vim.log.levels.ERROR)
end

return config
