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
---See |obazel-nvim.config| for an example configuration.
---
---The template provider will need to be registered with overseer:
--->lua
---     require("overseer").setup({
---         templates = {
---             "builtin",
---             "obazel",
---         },
---     }
---
---See:
---     |overseer.wrap_template|
---     https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md

---@brief ]]

---@toc obazel-contents

local obazel = {}

return obazel
