local bazel = require("obazel.bazel")

local testdata_dir = vim.fn.fnamemodify(debug.getinfo(1).short_src, ":p:h") .. "/testdata"

local workspace_dir = ("%s/basic"):format(testdata_dir)
local a_dir = ("%s/a"):format(workspace_dir)
local b_dir = ("%s/a/b"):format(workspace_dir)
local c_dir = ("%s/a/b/c"):format(workspace_dir)

describe("bazel", function()
    it("resolve_workspace_dir() returns nil when not in a bazel workspace", function()
        assert.are_nil(
            bazel.resolve_workspace_dir(testdata_dir),
            "resolve_workspace_dir(): should return nil when not in a bazel workspace"
        )
    end)
    it("resolve_workspace_dir() correctly resolves workspace dir", function()
        assert.are_equal(bazel.resolve_workspace_dir(workspace_dir), workspace_dir)
        assert.are_equal(bazel.resolve_workspace_dir(a_dir), workspace_dir)
        assert.are_equal(bazel.resolve_workspace_dir(b_dir), workspace_dir)
        assert.are_equal(bazel.resolve_workspace_dir(c_dir), workspace_dir)
    end)
    it("resolve_buildfile() returns nil when not in a bazel workspace", function()
        assert.are_nil(
            bazel.resolve_buildfile(testdata_dir),
            "resolve_buildfile(): should return nil when not in a bazel workspace"
        )
    end)
    it("resolve_buildfile() correctly resolves the BUILD.bazel file", function()
        assert.are_equal(bazel.resolve_buildfile(workspace_dir), ("%s/BUILD.bazel"):format(workspace_dir))
        assert.are_equal(bazel.resolve_buildfile(a_dir), ("%s/a/BUILD.bazel"):format(workspace_dir))
        assert.are_equal(bazel.resolve_buildfile(b_dir), ("%s/a/BUILD.bazel"):format(workspace_dir))
        assert.are_equal(bazel.resolve_buildfile(c_dir), ("%s/a/b/c/BUILD.bazel"):format(workspace_dir))
    end)
    it("resolve_target_prefix() returns an error if not in a bazel workspace", function()
        local prefix, err = bazel.resolve_target_prefix(testdata_dir)
        assert.are_nil(prefix)
        assert.are_equal(err, "failed to resolve workspace directory")
    end)
    it("resolve_target_prefix() correctly resolves the target prefix", function()
        local prefix, err = bazel.resolve_target_prefix(workspace_dir)
        assert.are_nil(err)
        assert.are_equal(prefix, "//")

        prefix, err = bazel.resolve_target_prefix(a_dir)
        assert.are_nil(err)
        assert.are_equal(prefix, "//a")

        prefix, err = bazel.resolve_target_prefix(b_dir)
        assert.are_nil(err)
        assert.are_equal(prefix, "//a")

        prefix, err = bazel.resolve_target_prefix(c_dir)
        assert.are_nil(err)
        assert.are_equal(prefix, "//a/b/c")
    end)
end)
