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
        local binary = template_config.binary or config.bazel_binary
        local metadata = template_config.metadata
        local components = template_config.components

        table.insert(
            templates,
            vim.tbl_deep_extend("force", {
                ---@type overseer.Params
                params = {
                    binary = { type = "string", optional = true, default = binary },
                    args = { type = "list", delimiter = " ", optional = true, default = template_config.args or {} },
                    after_target_args = {
                        type = "list",
                        delimiter = " ",
                        optional = true,
                        default = template_config.after_target_args or {},
                    },
                    env = { type = "opaque", optional = true, default = template_config.env },
                },
                builder = function(params)
                    vim.list_extend(params.args, params.after_target_args)
                    return {
                        cmd = { params.binary },
                        args = params.args,
                        env = params.env,
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
        local binary = query_config.binary or config.bazel_binary
        -- Used for the generated task name below, e.g. "/usr/bin/bazelisk" -> "bazelisk"
        local binary_tail = vim.fn.fnamemodify(binary, ":t")
        local args = query_config.args or {}
        local after_target_args = query_config.after_target_args or {}
        local metadata = query_config.metadata
        local components = query_config.components

        bazel.query(query, function(targets, err2)
            if err2 ~= nil then
                vim.notify(err2, vim.log.levels.ERROR)
            else
                for _, target in ipairs(targets) do
                    -- TODO toggleable in config to show short or long targets?
                    local short_target = remove_prefix(target, target_prefix)

                    -- Mirrors the order of the args built in `builder` below
                    -- (binary, base args, target, after_target_args), but with
                    -- `short_target` in place of the fully-qualified target
                    -- for readability. `args`/`after_target_args` default to
                    -- {}, so an entry with neither set produces just
                    -- "binary target", e.g. "foo //blah/blah:target".
                    local name_parts = { binary_tail }
                    vim.list_extend(name_parts, args)
                    table.insert(name_parts, short_target)
                    vim.list_extend(name_parts, after_target_args)

                    table.insert(
                        templates,
                        vim.tbl_deep_extend("force", {
                            name = table.concat(name_parts, " "),
                            ---@type overseer.Params
                            params = {
                                binary = { type = "string", optional = true, default = binary },
                                args = { type = "list", delimiter = " ", optional = true, default = args },
                                target = { type = "string", optional = true, default = target },
                                after_target_args = {
                                    type = "list",
                                    delimiter = " ",
                                    optional = true,
                                    default = after_target_args,
                                },
                                env = { type = "opaque", optional = true, default = query_config.env },
                            },
                            builder = function(params)
                                local qargs = vim.deepcopy(params.args)
                                table.insert(qargs, params.target)
                                vim.list_extend(qargs, params.after_target_args)
                                return {
                                    cmd = { params.binary },
                                    args = qargs,
                                    env = params.env,
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
