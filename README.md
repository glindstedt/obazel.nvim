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
require("stevearc/overseer.nvim").setup({
    templates = {
        "builtin",
        "obazel",
    },
})
# Or when using lazy.nvim:
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
        template = { name = "bazel run //:gazelle", priority = 50 },
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
          priority = 51,
        },
      },
      {
        query_template = 'kind(".*_binary", %s:*)',
        args = { "run" },
        template_file_definition = {
          tags = { "RUN" },
          priority = 52,
        },
      },
      {
        query_template = "kind(rule, %s:*)",
        args = { "build" },
        template_file_definition = {
          tags = { "BUILD" },
          priority = 100,
        },
      },
    },
  },
}
```
