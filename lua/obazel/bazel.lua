local config = require("obazel.config")

local bazel = {}

---Resolves the WORKSPACE file path
---@param directory nil|string
---@return nil|string
function bazel.resolve_workspace_file(directory)
    local search_dir
    if directory ~= nil then
        search_dir = vim.fn.fnamemodify(directory, ":p")
    else
        search_dir = vim.fn.getcwd()
    end
    local workspace_file = vim.fn.findfile("WORKSPACE", search_dir .. ";")
    if workspace_file == "" then
        return nil
    end
    return vim.fn.fnamemodify(workspace_file, ":p")
end

---Resolves the WORKSPACE directory
---@param directory nil|string
---@return nil|string
function bazel.resolve_workspace_dir(directory)
    local workspace_file = bazel.resolve_workspace_file(directory)
    if workspace_file == nil then
        return nil
    end
    return vim.fn.fnamemodify(workspace_file, ":p:h")
end

---Resolves the nearest BUILD.bazel file from the given directory
---@param directory string
---@return nil|string
function bazel.resolve_buildfile(directory)
    local search_dir = vim.fn.fnamemodify(directory, ":p")
    local buildfile = vim.fn.findfile("BUILD.bazel", search_dir .. ";")
    if buildfile == "" then
        return nil
    end
    return vim.fn.fnamemodify(buildfile, ":p")
end

---Resolves the bazel target prefix to use when querying for targets relevant to the given directory
---@param directory string
---@return nil|string prefix
---@return nil|string error_message
function bazel.resolve_target_prefix(directory)
    local workspace_dir = bazel.resolve_workspace_dir(directory)
    local buildfile = bazel.resolve_buildfile(directory)
    if workspace_dir == nil then
        return nil, "failed to resolve workspace directory"
    end
    if buildfile == nil then
        return nil, "failed to resolve BUILD.bazel file"
    end
    local relpath = vim.fn.fnamemodify(buildfile, string.format(":s?%s/??:h", workspace_dir))
    -- Special case, if directory == workspace_dir reldir will be '.' and we should just return //
    return "//" .. (relpath == "." and "" or relpath)
end

---Run a bazel query
---@param query string
---@return string[]
---@return nil|string error_message
function bazel.query(query)
    local obj = vim.system({ config.bazel_binary, "query", query }, { text = true }):wait()

    -- TODO this is weird behavior that will hopefully get fixed
    -- https://github.com/neovim/neovim/pull/26917
    if obj == nil then
        return {}, "failed to execute query"
    end

    if obj.code ~= 0 then
        vim.notify(("[stdout]:\n%s\n[stderr]:\n%s"):format(obj.stdout, obj.stderr), vim.log.levels.ERROR)
        return {}, "failed to execute query: code=" .. obj.code .. " signal=" .. obj.signal
    end

    local targets = {}
    local lines = vim.split(obj.stdout, "\n", { plain = true, trimempty = true })
    for _, line in ipairs(lines) do
        table.insert(targets, line)
    end
    return targets
end

return bazel
