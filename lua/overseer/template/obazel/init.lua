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

    -- Used for the generated task name below, e.g. "/usr/bin/bazelisk" -> "bazelisk"
    local binary_tail = vim.fn.fnamemodify(config.bazel_binary, ":t")

    for _, template_config in ipairs(config.overseer.templates) do
        local args = template_config.args
        if template_config.after_target_args then
            args = vim.list_extend(vim.deepcopy(args), template_config.after_target_args)
        end
        local env = template_config.env
        local metadata = template_config.metadata
        local components = template_config.components

        table.insert(
            templates,
            vim.tbl_deep_extend("force", {
                builder = function()
                    return {
                        cmd = { config.bazel_binary },
                        args = args,
                        env = env,
                        metadata = metadata,
                        components = components,
                    }
                end,
            }, template_config.template)
        )
    end

    local generators = config.overseer.generators
    local pending = #generators

    if pending == 0 then
        cb(templates)
        return
    end

    for _, query_config in ipairs(generators) do
        local query = query_config.query_template:format(target_prefix)

        bazel.query(query, function(targets, err2)
            if err2 ~= nil then
                vim.notify(err2, vim.log.levels.ERROR)
            else
                for _, target in ipairs(targets) do
                    -- TODO toggleable in config to show short or long targets?
                    local short_target = remove_prefix(target, target_prefix)
                    local qargs = vim.list_extend(vim.deepcopy(query_config.args), { target })
                    if query_config.after_target_args then
                        vim.list_extend(qargs, query_config.after_target_args)
                    end
                    local env = query_config.env
                    local metadata = query_config.metadata
                    local components = query_config.components

                    -- Mirrors the order of `cmd`/`qargs` below (binary, base
                    -- args, target, after_target_args), but with `short_target`
                    -- in place of the fully-qualified target for readability.
                    local name_parts = { binary_tail }
                    vim.list_extend(name_parts, query_config.args)
                    table.insert(name_parts, short_target)
                    if query_config.after_target_args then
                        vim.list_extend(name_parts, query_config.after_target_args)
                    end

                    table.insert(
                        templates,
                        vim.tbl_deep_extend("force", {
                            name = table.concat(name_parts, " "),
                            builder = function()
                                return {
                                    cmd = { config.bazel_binary },
                                    args = qargs,
                                    env = env,
                                    metadata = metadata,
                                    components = components,
                                }
                            end,
                        }, query_config.template_file_definition or {})
                    )
                end
            end
            pending = pending - 1
            if pending == 0 then
                cb(templates)
            end
        end)
    end
end

return provider
