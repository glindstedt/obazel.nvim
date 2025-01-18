---@diagnostic disable: lowercase-global
local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "obazel.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1",
}

test_dependencies = {
    "nlua",
}

source = {
    url = "git://github.com/glindstedt/" .. package,
}

build = {
    type = "builtin",
    copy_directories = {
        "doc",
        "plugin",
    },
}
