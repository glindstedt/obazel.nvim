lua_path_set := if env("LUA_PATH", "") == "" {
    "false"
} else if env("LUA_CPATH", "") == "" {
    "false"
} else {
    "true"
}

_default:
    @just --list --justfile {{justfile()}}

check:
    luacheck {{justfile_directory()}}

format:
    stylua -v --verify {{justfile_directory()}}

test: # make sure to set LUA_PATH and LUA_CPATH if they are not in the environment
    @[ "{{lua_path_set}}" = "true" ] || eval $(luarocks path --lua-version 5.1 --no-bin) && luarocks test --lua-version 5.1 --local
