---@mod obazel-nvim obazel.nvim
---
---@brief [[
---
---An |overseer|.nvim TemplateProvider for Bazel workspaces.
---
---The TemplateProvider can be configured with static templates and template
---generators, which will appear when you run |:OverseerRun|. The template
---generators will run bazel queries to gather targets. The queries are
---templated with a target prefix relative to the nearest BUILD.bazel file to
---the file in the current buffer.
---
---If there are targets that should always be available regardless of the
---current open file, for example `bazel run //:gazelle`, they can be
---configured as static templates.
---
---Call |obazel.setup()| to configure obazel.nvim, then register the template
---provider with overseer:
--->lua
---     require("obazel").setup({ ... })
---     require("overseer").setup({
---         templates = {
---             "builtin",
---             "obazel",
---         },
---     }
---
---See |obazel-nvim.config| for an example configuration.
---
---See:
---     https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md

---@brief ]]

---@toc obazel-contents

local obazel = {}

---Configure obazel.nvim. Must be called before overseer.nvim collects
---templates (e.g. via |:OverseerRun| or `preload_task_cache()`).
---@param opts? obazel.Config
function obazel.setup(opts)
    require("obazel.config.internal").setup(opts)
end

return obazel
