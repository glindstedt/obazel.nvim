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

obazel.nvim is configured by calling `require("obazel").setup({...})`, and
the template provider needs to be registered with overseer:

```lua
require("obazel").setup({
    -- see "Example Configuration" below
})
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

`obazel.setup()` must run before overseer collects templates (e.g. before
`:OverseerRun` or `preload_task_cache()` is invoked), so call it as part of
your plugin configuration.

The template provider does not come with any default templates. They must be
configured through `obazel.setup()`.

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
require("obazel").setup({
  -- (optional) The binary used to invoke bazel commands
  -- bazel_binary = "bazel",
  overseer = {
    -- Static task templates, for tasks that should always be available
    templates = {
      {
        args = { "run", "//:gazelle" },
        template = { name = "bazel run //:gazelle", priority = 50 },
      },
      {
        args = { "test", "//..." },
        -- Appended after the target (unlike `args`, which comes before it),
        -- e.g. for flags you want passed through to the test binary itself
        -- via `--`.
        after_target_args = { "--", "--some-flag" },
        env = { BAZEL_CONFIG = "ci" },
        metadata = { kind = "test" },
        components = { "default", { "on_output_parse", errorformat = "..." } },
        template = { name = "bazel test //..." },
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
      {
        -- `args` is optional; omitting it produces just "binary target",
        -- e.g. for a custom wrapper script that takes a target directly.
        query_template = "kind(rule, %s:*)",
        binary = "foo",
        template_file_definition = {
          tags = { "FOO" },
        },
      },
    },
  },
})
```

Each entry in `templates`/`generators` also accepts `args`, `after_target_args`,
`binary`, `cwd`, `env`, `metadata`, `components`, and `relative_file_root`,
which are merged into the `overseer.TaskDefinition` produced for that
template/generated task (see `obazel.TemplateConfig` and
`obazel.GeneratorConfig`). These are distinct from
`template`/`template_file_definition`, which only affect the
`overseer.TemplateDefinition` shown in `:OverseerRun`; fields like
`components`, `env`, and `metadata` have no effect there, since they belong
to the task, not the template. `args` and `binary` are both optional:
omitting `args` produces a command with none (just `binary target` for
generators), and omitting `binary` falls back to the top-level
`bazel_binary`.

`cwd` sets the task's working directory, and `relative_file_root` is used to
resolve relative paths reported by components like `on_output_parse` (e.g.
compiler diagnostics). Both default to the resolved bazel workspace root, and
both can be overridden with a fixed string or a function that takes the
workspace root and returns the path to use, e.g. to fall back to Neovim's
own cwd instead:

```lua
{
  args = { "run", "//:gazelle" },
  cwd = function(workspace_root)
    return vim.fn.getcwd()
  end,
  template = { name = "bazel run //:gazelle" },
}
```

`relative_file_root` is resolved independently of `cwd`, and does *not* fall
back to task `cwd` when left unset the way overseer's own `relative_file_root`
component param does. Bazel's own diagnostics are reported relative to the
workspace root regardless of where the task actually runs, so if you override
`cwd` (e.g. to run a task from Neovim's cwd, as above) without also touching
`relative_file_root`, diagnostics still resolve against the workspace root,
which is almost always what you want.

The name of a generated task (from `generators`, not `templates`) starts
with the tail of `binary` (its own `binary` if set, otherwise the tail of
`config.bazel_binary`, e.g. `/usr/bin/bazelisk` becomes `bazelisk`),
followed by `args`, the resolved target, and `after_target_args`, so task
names stay accurate and distinct even when `binary`, `args`, or
`after_target_args` differ between generator entries.

Because `template`/`template_file_definition` are plain
`overseer.TemplateDefinition`/`overseer.TemplateFileDefinition` tables, you
can also supply your own `builder` there to fully replace obazel's. Doing so
still gives you access to everything obazel would otherwise have used to
build the task: `binary`, `args`, `after_target_args`, `cwd`, `env`, `metadata`,
`components`, `relative_file_root`, and (for `generators` only) the resolved
`target`, via the `params` argument overseer passes to `builder(params)`:

```lua
{
  query_template = "tests(%s:*)",
  args = { "test" },
  template_file_definition = {
    builder = function(params)
      return {
        cmd = { params.binary },
        args = { "test", params.target, "--test_output=all" },
        env = params.env,
      }
    end,
  },
}
```
