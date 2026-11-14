---
id: writing-plugins
title: Writing a plugin
type: reference
category: plugins
keywords: [plugin, develop, package, rcmdrshiny_plugin, dialogs, menus, namespace]
aliases: [plugin-development, developer-guide]
dialogs: []
commands: [RcmdrShiny.plugin, plugin_dialog, load_plugin_package]
packages: [RcmdrShiny]
related: [plugins, writing-help-topics]
language: en
status: documented
---

# Writing a plugin

A plugin is an ordinary R package with a `rcmdrshiny_plugin()` function and,
optionally, a menu file and help topics.

## Package skeleton

```text
RcmdrShinyPlugin.Example/
├─ DESCRIPTION
├─ NAMESPACE
├─ R/
│  ├─ plugin.R
│  ├─ dialogs.R
│  └─ commands.R
├─ inst/menus/module.yml
├─ inst/etc/rcmdrshiny-menus.txt   # legacy migration source
├─ inst/help/index.yml
├─ man/
└─ tests/testthat/
```

`DESCRIPTION` imports `RcmdrShiny` and, if the dialogs use HTML helpers,
`htmltools`.

## Register the plugin

```r
rcmdrshiny_plugin <- function() {
  RcmdrShiny::RcmdrShiny.plugin(
    name = "RcmdrShinyPlugin.Example",
    menus = system.file("etc", "rcmdrshiny-menus.txt",
                        package = "RcmdrShinyPlugin.Example"),
    dialogs = example_dialogs(),
    version = "0.1.0",
    description = "Example plugin."
  )
}
```

Export the function in `NAMESPACE`:

```r
export(rcmdrshiny_plugin)
```

## Build a dialog

```r
example_dialogs <- function() {
  list(
    examplePlot = RcmdrShiny::plugin_dialog(
      id = "examplePlot",
      title = "Example plot",
      help_topic = "example-plot",
      ui = function(state, memory) {
        htmltools::tagList(
          RcmdrShiny::var_input(
            "examplePlot_variable", "Variable",
            RcmdrShiny::numeric_variables(state),
            if (is.null(memory)) NULL else memory$variable
          )
        )
      },
      on_ok = function(input, state) {
        variable <- input$examplePlot_variable
        if (is.null(variable) || !nzchar(variable)) {
          return(list(error = "Choose a variable."))
        }
        list(
          commands = sprintf("plot(%s$%s)",
                             RcmdrShiny::active_dataset(state), variable),
          memory = list(variable = variable),
          plot = TRUE
        )
      }
    )
  )
}
```

`on_ok()` returns either `list(error = ...)` or `list(commands = ...,
memory = ..., plot = ...)`.  Commands are shown in the **Script** tab exactly as
returned, so keep them short and readable.

## Menu file

The 15 bundled plugins are first-party modules and use `inst/menus/module.yml`
with stable `menu_id` / `item_id` values; see `topic:menu-structure`. The legacy
format below is still read for script-only plugins and for migration: one row
per menu or item, whitespace separated, with quoted labels.

```text
menu  exampleMenu  topMenu  ""  ""  ""  ""
item  exampleMenu  command  "Example plot..."  examplePlot  "activeDataSetP()"  ""
item  topMenu      cascade  "Example"         exampleMenu  ""  ""
```

## SDK v2

`plugin_api_version()` is `2`. `RcmdrShiny.plugin()` accepts `api_version` and
records a `module_id`; `plugin_contract()` lists the stable fields. The
extension hooks are additive:

- `plugin_ui_component(name, render = ...)` registers a UI factory;
- `plugin_register_preset(dialog, name, values)` adds a global preset;
- `plugin_register_workflow(workflow)` adds a guided workflow;
- `plugin_register_chart_type(chart_type)` adds a chart type;
- `plugin_register_report_template(template)` adds a report template;
- `plugin_help_try_it(topic, examples)` appends runnable examples;
- `plugin_dialog_preview(spec)` renders a dialog body without a session.

A plugin cannot replace a built-in workflow, chart type or report template by
id. Presets merge with session presets, and the session wins. Loading can be
queued with `options(RcmdrShiny.lazy_plugins = TRUE)`.

## Help topics

Add `inst/help/index.yml` and Markdown topics; the loader discovers them
automatically.  See `topic:writing-help-topics`.

## Test the plugin

```r
testthat::test_local("plugins/RcmdrShinyPlugin.Example")
R CMD check RcmdrShinyPlugin.Example_0.1.0.tar.gz
```

## See also

- `topic:plugins`
- `topic:writing-help-topics`
