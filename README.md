# obazel.nvim

An [overseer.nvim](https://github.com/stevearc/overseer.nvim) template provider for [Bazel](https://bazel.build/).

## Installation

### [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim)
```vim
:Rocks install obazel.nvim
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ "glindstedt/obazel.nvim" }
```

## Configuration

The template provider needs to be registered with overseer:

```lua
require("overseer").setup({
    templates = {
        "builtin",
        "obazel",
    },
})
-- Or when using lazy.nvim:
{
  "stevearc/overseer.nvim",
  opts = {
    templates = {
      "builtin",
      "obazel",
    },
}
```

The template provider does not come with any default templates. They must be
configured through the `vim.g.obazel` table.

> [!WARNING]
> obazel.nvim runs `bazel query` asynchronously when populating the task list,
> which avoids freezing the UI while the query runs. However, overseer.nvim
> imposes a default timeout of 3000ms (`template_timeout_ms`) on template
> providers; if the Bazel server is not yet running or the workspace is large,
> the query may not complete in time and `:OverseerRun` may silently show no
> results from obazel.nvim.

If `:OverseerRun` doesn't seem to do anything on first run, or your picker
doesn't show any obazel-configured tasks, try increasing the timeout in your overseer setup:

```lua
require("overseer").setup({
    template_timeout_ms = 10000,
})
```

Alternatively, you can pre-warm the cache when a buffer is opened so the query
runs in the background before you invoke `:OverseerRun`:

```lua
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        require("overseer").preload_task_cache()
    end,
})
```

### Example Configuration

```lua
---@module 'obazel'
---@type obazel.Config
vim.g.obazel = {
  -- (optional) The binary used to invoke bazel commands
  -- bazel_binary = "bazel",
  overseer = {
    -- Static task templates, for tasks that should always be available
    templates = {
      {
        args = { "run", "//:gazelle" },
        template = { name = "bazel run //:gazelle" },
      },
    },
    -- Task templates generated via bazel queries. The '%s' sign in the
    -- query_template will be replaced with the target_prefix, which is the
    -- prefix to the nearest BUILD.bazel file, e.g. '//foo/bar'
    generators = {
      {
        query_template = "tests(%s:*)",
        args = { "test" },
        template_file_definition = {
          tags = { "TEST" },
        },
      },
      {
        query_template = 'kind(".*_binary", %s:*)',
        args = { "run" },
        template_file_definition = {
          tags = { "RUN" },
        },
      },
      {
        query_template = "kind(rule, %s:*)",
        args = { "build" },
        template_file_definition = {
          tags = { "BUILD" },
        },
      },
    },
  },
}
```
