-- Use debug.getinfo's untruncated `source` field (not `short_src`, which Lua
-- truncates to LUA_IDSIZE and is meant for error-message display only) so
-- this resolves correctly regardless of how deeply nested the checkout is.
local this_file = debug.getinfo(1, "S").source:sub(2)
local testdata_dir = vim.fn.fnamemodify(this_file, ":p:h") .. "/testdata"
local workspace_dir = ("%s/basic"):format(testdata_dir)

--- Reloads the obazel/overseer template provider modules with a fresh
--- `vim.g.obazel` config and a stubbed `bazel.query`, so each test is
--- isolated from module-level state cached by other spec files.
---@param obazel_config table
---@param query_results string[]
---@return overseer.TemplateProvider
local function fresh_provider(obazel_config, query_results)
    for _, name in ipairs({
        "overseer.template.obazel",
        "obazel.bazel",
        "obazel.config.internal",
        "obazel.config.check",
    }) do
        package.loaded[name] = nil
    end

    vim.g.obazel = obazel_config

    local bazel = require("obazel.bazel")
    bazel.query = function(_, callback)
        callback(query_results, nil)
    end

    return require("overseer.template.obazel")
end

--- Runs provider.generator() synchronously (safe since our bazel.query stub
--- invokes its callback synchronously) and returns the generated templates.
---@param provider overseer.TemplateProvider
---@param dir string
---@return overseer.TemplateDefinition[]
local function generate(provider, dir)
    local result
    local err = provider.generator({ dir = dir }, function(templates)
        result = templates
    end)
    assert.is_nil(err)
    assert.is_table(result)
    return result
end

describe("overseer.template.obazel provider aliases", function()
    it("aliases each generated template with its full bazel target label", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = {
                    {
                        query_template = "kind(rule, %s:*)",
                        args = { "build" },
                        template_file_definition = { tags = { "BUILD" } },
                    },
                },
            },
        }, { "//foo/bar:baz", "//foo/bar/qux:target" })

        local templates = generate(provider, workspace_dir)

        assert.equal(2, #templates)
        assert.is_true(vim.tbl_contains(templates[1].aliases, "//foo/bar:baz"))
        assert.is_true(vim.tbl_contains(templates[2].aliases, "//foo/bar/qux:target"))
    end)

    it("aliases each generated template with the exact command string that will run", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = {
                    {
                        query_template = "kind(rule, %s:*)",
                        binary = "bazel",
                        args = { "build", "--config=opt" },
                        after_target_args = { "--", "--verbose" },
                    },
                },
            },
        }, { "//foo/bar:baz" })

        local templates = generate(provider, workspace_dir)

        assert.equal(1, #templates)
        assert.is_true(vim.tbl_contains(templates[1].aliases, "bazel build --config=opt //foo/bar:baz -- --verbose"))
    end)

    it("sets aliases independently for each generator's templates", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = {
                    { query_template = "kind(rule, %s:*)", args = { "build" } },
                    { query_template = 'kind(".*_test", %s:*)', args = { "test" } },
                },
            },
        }, { "//foo:target" })

        local templates = generate(provider, workspace_dir)

        assert.equal(2, #templates)
        for _, tmpl in ipairs(templates) do
            assert.is_true(vim.tbl_contains(tmpl.aliases, "//foo:target"))
        end
    end)
end)

--- Simulates overseer's own param resolution (using each param's default),
--- since the provider module doesn't depend on overseer being on the
--- runtimepath to be unit-tested.
---@param tmpl overseer.TemplateDefinition
---@return table
local function default_params(tmpl)
    local params = {}
    for name, spec in pairs(tmpl.params) do
        params[name] = spec.default
    end
    return params
end

describe("overseer.template.obazel provider metadata", function()
    it("attaches bazel_target to the built task's metadata", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = { { query_template = "kind(rule, %s:*)", args = { "build" } } },
            },
        }, { "//foo/bar:baz" })

        local tmpl = generate(provider, workspace_dir)[1]
        local task_def = tmpl.builder(default_params(tmpl))

        assert.equal("//foo/bar:baz", task_def.metadata.bazel_target)
    end)

    it("preserves user-configured metadata alongside bazel_target", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = {
                    { query_template = "kind(rule, %s:*)", args = { "build" }, metadata = { foo = "bar" } },
                },
            },
        }, { "//foo:target" })

        local tmpl = generate(provider, workspace_dir)[1]
        local task_def = tmpl.builder(default_params(tmpl))

        assert.equal("//foo:target", task_def.metadata.bazel_target)
        assert.equal("bar", task_def.metadata.foo)
    end)

    it("lets an explicit bazel_target in user-configured metadata take precedence", function()
        local provider = fresh_provider({
            bazel_binary = "true",
            overseer = {
                generators = {
                    {
                        query_template = "kind(rule, %s:*)",
                        args = { "build" },
                        metadata = { bazel_target = "custom" },
                    },
                },
            },
        }, { "//foo:target" })

        local tmpl = generate(provider, workspace_dir)[1]
        local task_def = tmpl.builder(default_params(tmpl))

        assert.equal("custom", task_def.metadata.bazel_target)
    end)
end)
