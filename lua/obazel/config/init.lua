---@module 'overseer'

---@mod obazel-nvim.config obazel.nvim configuration
---
---@brief [[
---
---For static task templates, see |obazel.TemplateConfig|. To configure template
---generators see |obazel.GeneratorConfig|. No templates are defined by default.
---
---------------------------------------------------------------------------------
---Example configuration
--->lua
---     ---@module 'obazel'
---     ---@type obazel.Config
---     vim.g.obazel = {
---       -- (optional) The binary used to invoke bazel commands
---       bazel_binary = "bazel",
---       overseer = {
---         -- static task templates
---         templates = {
---           {
---             args = { "run", "//:gazelle" },
---             template = { name = "bazel run //:gazelle", priority = 50 },
---           },
---         },
---         -- task templates generated via bazel queries
---         generators = {
---           {
---             query_template = "tests(%s:*)",
---             args = { "test" },
---             template_file_definition = {
---               tags = { "TEST" },
---               priority = 51,
---             },
---           },
---           {
---             query_template = 'kind(".*_binary", %s:*)',
---             args = { "run" },
---             template_file_definition = {
---               tags = { "RUN" },
---               priority = 52,
---             },
---           },
---           {
---             query_template = "kind(rule, %s:*)",
---             args = { "build" },
---             template_file_definition = {
---               tags = { "BUILD" },
---               priority = 100,
---             },
---           },
---         },
---       },
---     }
---
---@brief ]]

---@class obazel.Config
---@field bazel_binary? string (optional) (default: "bazel")
---@field overseer? obazel.OverseerConfig (optional)

---@class obazel.OverseerConfig
---@field templates? obazel.TemplateConfig[] (optional) static task templates
---@field generators? obazel.GeneratorConfig[] (optional) bazel query based template generators

---A static template definition for bazel targets that you always want to have
---available. For example `bazel run //:gazelle`.
---
---Use the `template` argument to set the `name` and `priority` of the task:
--->lua
---     {
---         args = { "run", "//:gazelle" },
---         template = { name = "bazel run //:gazelle", priority = 50 },
---     }
---@class obazel.TemplateConfig
---@field args string[] the args that will be passed to bazel
---@field template overseer.TemplateDefinition the template definition

---A template generator using a bazel query.
---
---The query_template should be a string that contains '%s' which will be
---replaced with the resolved `target_prefix` for the file in the current
---buffer. The `target_prefix` is resolved using
---|obazel-nvim.bazel.resolve_target_prefix|.
---
---Use the `template_file_definition` to override values in the base template:
--->lua
---     {
---       query_template = "tests(%s:*)",
---       args = { "test" },
---       template_file_definition = {
---         tags = { "TEST" },
---         priority = 51,
---       },
---     }
---@class obazel.GeneratorConfig
---@field query_template string a query template where '%s' will be replaced by the target_prefix
---@field args string[] args that will be passed to bazel before the targets
---@field template_file_definition? table (optional) overrides values in the base overseer.TemplateFileDefinition
---@see overseer.wrap_template

---@type obazel.Config | fun():obazel.Config | nil
vim.g.obazel = vim.g.obazel

local config = {}

return config
