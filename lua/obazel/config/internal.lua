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

---This table is returned by `require("obazel.config.internal")` and is
---mutated in place by `config.setup()`, rather than replaced, so that
---modules which grabbed a reference to it before `setup()` was called still
---observe the final values.
---@type obazel.InternalConfig
local config = vim.deepcopy(default_config)

---@param user_config? obazel.Config
function config.setup(user_config)
    user_config = user_config or {}

    local unrecognized_configs = check.get_unrecognized_keys(user_config, default_config)
    local merged = vim.tbl_deep_extend("force", default_config, user_config)

    config.bazel_binary = merged.bazel_binary
    config.overseer = merged.overseer
    config.debug_info = { unrecognized_configs = unrecognized_configs }

    if #unrecognized_configs > 0 then
        vim.notify(
            "unrecognized configs passed to obazel.setup(): " .. vim.inspect(unrecognized_configs),
            vim.log.levels.ERROR
        )
    end

    local ok, err = check.validate(config)
    if not ok then
        vim.notify("obazel: " .. err, vim.log.levels.ERROR)
    end
end

return config
