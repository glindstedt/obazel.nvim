---@module 'overseer'

local check = require("obazel.config.check")

---@class obazel.TemplateConfig
---@field template overseer.TemplateDefinition
---@field args string[]

---@class obazel.GeneratorConfig
---@field query_template string a string template
---@field args string[]
---@field template_file_definition? table (optional)

---@class obazel.OverseerConfig
---@field templates? obazel.TemplateConfig[]
---@field generators? obazel.GeneratorConfig[] (optional) TODO

---@class obazel.Config
---@field bazel_binary? string (optional) the bazel binary to use
---@field overseer? obazel.OverseerConfig (optional) TODO

---@type obazel.Config | fun():obazel.Config | nil
vim.g.obazel = vim.g.obazel

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
        -- Ignore overseer.templates and overseer.generators, the function doesn't handle arrays
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
