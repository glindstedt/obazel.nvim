---@mod obazel-nvim.overseer overseer.nvim template provider for Bazel
---
---@brief [[
---
---Template provider for |overseer|.nvim.
---
---@brief ]]

local bazel = require("obazel.bazel")
local config = require("obazel.config.internal")
local overseer = require("overseer")

local config_is_valid = require("obazel.config.check").validate(config)

local function remove_prefix(str, prefix)
    if str:sub(1, #prefix) == prefix then
        return str:sub(#prefix + 1)
    else
        return str
    end
end

---@type overseer.TemplateDefinition
local base_template = {
    name = "base",
    priority = 60,
    params = {
        args = { type = "list", delimiter = " " },
    },
    builder = function(params)
        return {
            cmd = { config.bazel_binary },
            args = params.args,
        }
    end,
}

---@type overseer.TemplateProvider
local provider = {
    name = "bazel",
}

provider.condition = {
    callback = function(opts)
        if not config_is_valid then
            return false, "Invalid config"
        end
        if not bazel.resolve_workspace_file(opts.dir) then
            return false, "Not in a bazel workspace."
        end
        if not bazel.resolve_buildfile(opts.dir) then
            return false, "No BUILD.bazel file found"
        end
        return true
    end,
}

---@param opts overseer.SearchParams
function provider.cache_key(opts)
    return bazel.resolve_buildfile(opts.dir)
end

function provider.generator(opts, cb)
    -- Resolve the target prefix for the given directory
    local target_prefix, err1 = bazel.resolve_target_prefix(opts.dir)
    if target_prefix == nil or err1 ~= nil then
        vim.notify(err1, vim.log.levels.ERROR)
        cb({})
        return
    end

    ---@type overseer.TemplateDefinition[]
    local templates = {}

    -- Set up static templates
    for _, template_config in ipairs(config.overseer.templates) do
        table.insert(
            templates,
            overseer.wrap_template(base_template, template_config.template, { args = template_config.args })
        )
    end

    -- Generate templates through bazel queries
    for _, query_config in ipairs(config.overseer.generators) do
        local query = query_config.query_template:format(target_prefix)

        local targets, err2 = bazel.query(query)
        if err2 ~= nil then
            vim.notify(err2, vim.log.levels.ERROR)
        else
            for _, target in ipairs(targets) do
                -- TODO toggleable in config to show short or long targets?
                local short_target = remove_prefix(target, target_prefix)

                ---@type overseer.TemplateDefinition
                local template = vim.tbl_deep_extend(
                    "force",
                    { name = ("bazel %s %s"):format(table.concat(query_config.args, " "), short_target) },
                    query_config.template_file_definition ~= nil and query_config.template_file_definition or {}
                )

                table.insert(
                    templates,
                    overseer.wrap_template(base_template, template, {
                        args = { unpack(query_config.args), target },
                    })
                )
            end
        end
    end

    cb(templates)
end

return provider
