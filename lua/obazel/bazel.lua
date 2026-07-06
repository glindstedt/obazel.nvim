---@mod obazel-nvim.bazel Bazel utilities
---
---@brief [[
---
---Utilities for working with Bazel workspaces
---
---@brief ]]

local config = require("obazel.config.internal")

local bazel = {}

---Resolves the WORKSPACE file path
---Recognises MODULE.bazel, REPO.bazel (Bzlmod), WORKSPACE.bazel, and WORKSPACE
---as workspace root markers, checked in that order of preference.
---@param directory nil|string (default: vim.fn.getcwd())
---@return nil|string
function bazel.resolve_workspace_file(directory)
    local search_dir
    if directory ~= nil then
        search_dir = vim.fn.fnamemodify(directory, ":p")
    else
        search_dir = vim.fn.getcwd()
    end
    for _, name in ipairs({ "MODULE.bazel", "REPO.bazel", "WORKSPACE.bazel", "WORKSPACE" }) do
        local found = vim.fn.findfile(name, search_dir .. ";")
        if found ~= "" then
            return vim.fn.fnamemodify(found, ":p")
        end
    end
    return nil
end

---Resolves the WORKSPACE directory
---@param directory nil|string (default: vim.fn.getcwd())
---@return nil|string
function bazel.resolve_workspace_dir(directory)
    local workspace_file = bazel.resolve_workspace_file(directory)
    if workspace_file == nil then
        return nil
    end
    return vim.fn.fnamemodify(workspace_file, ":p:h")
end

---Resolves the nearest BUILD or BUILD.bazel file from the given directory
---Prefers BUILD.bazel if both exist in the same directory
---@param directory string
---@return nil|string
function bazel.resolve_buildfile(directory)
    local search_dir = vim.fn.fnamemodify(directory, ":p")

    -- Find both BUILD and BUILD.bazel files
    local build_bazel = vim.fn.findfile("BUILD.bazel", search_dir .. ";")
    local build_file = vim.fn.findfile("BUILD", search_dir .. ";")

    -- If neither found, return nil
    if build_bazel == "" and build_file == "" then
        return nil
    -- If only one found, return that one
    elseif build_bazel == "" then
        return vim.fn.fnamemodify(build_file, ":p")
    elseif build_file == "" then
        return vim.fn.fnamemodify(build_bazel, ":p")
    end

    -- Both found - compare directories to find the nearest
    local build_bazel_dir = vim.fn.fnamemodify(build_bazel, ":p:h")
    local build_file_dir = vim.fn.fnamemodify(build_file, ":p:h")

    -- If they're in the same directory, prefer BUILD.bazel
    if build_bazel_dir == build_file_dir then
        return vim.fn.fnamemodify(build_bazel, ":p")
    -- Otherwise, return the one that's closer (shorter path from search_dir)
    elseif #build_bazel_dir >= #build_file_dir then
        return vim.fn.fnamemodify(build_bazel, ":p")
    else
        return vim.fn.fnamemodify(build_file, ":p")
    end
end

---Resolves the bazel target prefix to use when querying for targets relevant
---to the given directory.
---
---For example if the provided directory is `one/two/three`, and the nearest
---BUILD.bazel file is `one/two/BUILD.bazel`, the target prefix will be
---`//one/two`
---
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
---@return string[] targets
---@return nil|string error_message
---@usage `bazel.query("//foo/bar/...")`
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
