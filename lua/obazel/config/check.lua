---@module 'obazel.config.internal'

---@mod obazel-nvim.config.check
---
---@brief [[
---
---Config validation (internal)
---
---@brief ]]

local check = {}

---@param tbl table to validate
---@see vim.validate
---@return boolean is_valid
---@return nil|string error_message
local function validate(tbl)
    local ok, err = pcall(vim.validate, tbl)
    return ok or false, "obazel: invalid config" .. (err and ": " .. err or "")
end

---@param cfg obazel.InternalConfig
---@return boolean is_valid
---@return nil|string error_message
function check.validate(cfg)
    local ok, err = validate({
        bazel_binary = { cfg.bazel_binary, "string" },
    })
    if not ok then
        return false, err
    end

    if vim.fn.executable(cfg.bazel_binary) ~= 1 then
        return false, ("config.bazel_binary: Cannot execute '%s'"):format(cfg.bazel_binary)
    end
    return true
end

---Check if the given table is an array
---@param tbl table
---@return boolean
local function is_array(tbl)
    for i = 1, #tbl do
        if tbl[i] == nil then
            return false
        end
    end
    return true
end

---Recursively check a table for unrecognized keys, using a default table as a
---reference. Ignores any value that is an array.
---
---Inspired from https://github.com/nvim-neorocks/rocks.nvim/blob/09c93f1b235dc07de18e63a5392bde17dddc29dd/lua/rocks/config/check.lua#L56
---@param tbl table
---@param default_tbl table
---@return string[]
function check.get_unrecognized_keys(tbl, default_tbl)
    is_array(tbl)
    local unrecognized_keys = {}
    for k, _ in pairs(tbl) do
        unrecognized_keys[k] = true
    end
    for k, _ in pairs(default_tbl) do
        unrecognized_keys[k] = false
    end
    local ret = {}
    for k, _ in pairs(unrecognized_keys) do
        if unrecognized_keys[k] then
            ret[k] = k
        end
        if type(default_tbl[k]) == "table" and tbl[k] and not is_array(tbl[k]) then
            for _, subk in pairs(check.get_unrecognized_keys(tbl[k], default_tbl[k])) do
                local key = k .. "." .. subk
                ret[key] = key
            end
        end
    end
    return vim.tbl_keys(ret)
end

return check
