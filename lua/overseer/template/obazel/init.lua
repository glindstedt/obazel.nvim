---@mod obazel-nvim.overseer overseer.nvim template provider for Bazel
---
---@brief [[
---
---Template provider for |overseer|.nvim.
---
---@brief ]]

local bazel = require("obazel.bazel")
local config = require("obazel.config.internal")

local config_is_valid = require("obazel.config.check").validate(config)

local function remove_prefix(str, prefix)
    if str:sub(1, #prefix) == prefix then
        return str:sub(#prefix + 1)
    else
        return str
    end
end

---@type overseer.TemplateProvider
local provider = {
    name = "bazel",
}

---@param opts overseer.SearchParams
function provider.cache_key(opts)
    return bazel.resolve_buildfile(opts.dir)
end

function provider.generator(opts, cb)
    if not config_is_valid then
        return "Invalid obazel config"
    end

    local target_prefix, err1 = bazel.resolve_target_prefix(opts.dir)
    if err1 ~= nil then
        return err1
    end

    ---@type overseer.TemplateDefinition[]
    local templates = {}

    for _, template_config in ipairs(config.overseer.templates) do
        local args = template_config.args
        table.insert(
            templates,
            vim.tbl_deep_extend("force", {
                builder = function()
                    return {
                        cmd = { config.bazel_binary },
                        args = args,
                    }
                end,
            }, template_config.template)
        )
    end

    for _, query_config in ipairs(config.overseer.generators) do
        local query = query_config.query_template:format(target_prefix)

        local targets, err2 = bazel.query(query)
        if err2 ~= nil then
            vim.notify(err2, vim.log.levels.ERROR)
        else
            for _, target in ipairs(targets) do
                -- TODO toggleable in config to show short or long targets?
                local short_target = remove_prefix(target, target_prefix)
                local qargs = vim.list_extend(vim.deepcopy(query_config.args), { target })

                table.insert(
                    templates,
                    vim.tbl_deep_extend("force", {
                        name = ("bazel %s %s"):format(table.concat(query_config.args, " "), short_target),
                        builder = function()
                            return {
                                cmd = { config.bazel_binary },
                                args = qargs,
                            }
                        end,
                    }, query_config.template_file_definition or {})
                )
            end
        end
    end

    cb(templates)
end

return provider
