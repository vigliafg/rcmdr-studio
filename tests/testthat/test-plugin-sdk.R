# P7.13 and P7.14: plugin SDK v2 and its extension hooks.

test_that("the plugin contract is versioned and documented", {
  expect_equal(plugin_api_version(), 2L)
  contract <- plugin_contract()
  expect_equal(contract$api_version, 2L)
  expect_true(all(c("module_id", "menu_id", "item_id", "command_id") %in%
                    contract$menu))
  expect_true(all(c("id", "title", "ui", "on_ok") %in% contract$dialog))
  expect_true(all(c("component", "preset", "workflow", "chart_type",
                    "report_template", "help_examples") %in%
                    contract$extension))
})

test_that("a plugin records its API version and module id", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  plugin <- RcmdrShiny.plugin(
    name = "RcmdrShinyPlugin.Demo",
    commands = list(demoCommand = function(state) NULL)
  )
  expect_equal(plugin$api_version, 2L)
  expect_equal(plugin$module_id, "demo")

  expect_error(
    RcmdrShiny.plugin(name = "future", api_version = 99L),
    "Unsupported plugin API version"
  )
  expect_equal(plugin_module_id("RcmdrShinyPlugin.FactoMineR"),
               "factominer")
})

test_that("UI components can be registered and rendered", {
  plugin_extensions_reset()
  on.exit(plugin_extensions_reset(), add = TRUE)

  plugin_ui_component("badge", render = function(text, class = "badge") {
    htmltools::tags$span(class = class, text)
  })
  html <- as.character(plugin_ui_component("badge", "Hello"))
  expect_match(html, "Hello")
  expect_match(html, "badge")
  expect_error(plugin_ui_component("missing"), "Unknown plugin component")
})

test_that("plugin presets merge with session presets and session wins", {
  plugin_extensions_reset()
  on.exit(plugin_extensions_reset(), add = TRUE)
  state <- AppState(new.env())

  plugin_register_preset("numericalSummaries", "Teaching",
                         list(mean = TRUE, sd = TRUE))
  presets <- dialog_presets_for(state, "numericalSummaries")
  expect_true("Teaching" %in% names(presets))
  expect_true(dialog_preset_get(state, "numericalSummaries",
                                "Teaching")$mean)

  dialog_preset_save(state, "numericalSummaries", "Teaching",
                     list(mean = FALSE))
  expect_false(dialog_preset_get(state, "numericalSummaries", "Teaching")$mean)
})

test_that("plugin workflows extend but do not replace built-ins", {
  plugin_extensions_reset()
  on.exit(plugin_extensions_reset(), add = TRUE)

  custom <- workflow_spec(
    id = "custom-flow", title = "Custom flow", description = "Demo",
    steps = list(workflow_step("one", "One", command = "countMissing"))
  )
  plugin_register_workflow(custom)
  expect_true("custom-flow" %in% names(workflow_registry()))
  expect_equal(workflow_find("custom-flow")$title, "Custom flow")

  plugin_register_workflow(workflow_spec(
    id = "describe", title = "Replacement", description = "No",
    steps = list()
  ))
  expect_equal(workflow_registry()[["describe"]]$title,
               workflow_registry_builtin()[["describe"]]$title)
})

test_that("plugin chart types and report templates are additive", {
  plugin_extensions_reset()
  on.exit(plugin_extensions_reset(), add = TRUE)

  plugin_register_chart_type(list(
    id = "plugin-test-chart", label = "Plugin chart", group = "custom",
    mapping = list()
  ))
  expect_true("plugin-test-chart" %in% names(chart_types()))

  plugin_register_chart_type(list(
    id = "histogram", label = "Taken", group = "custom"
  ))
  expect_equal(chart_types()[["histogram"]]$label,
               chart_types_builtin()[["histogram"]]$label)

  plugin_register_report_template(list(
    id = "plugin-template", title = "Plugin template",
    description = "Demo", build = function(...) "text"
  ))
  expect_true("plugin-template" %in% names(report_templates()))
})

test_that("plugin_help_try_it appends runnable examples", {
  before <- length(help_topic("projects")$examples %||% list())
  id <- plugin_help_try_it("projects", list(
    list(code = "RcmdrShiny:::project_summary(AppState())",
         title = "Summary", runnable = TRUE)
  ))
  expect_equal(id, "projects")
  after <- help_topic("projects")$examples
  expect_equal(length(after), before + 1L)
  expect_true(isTRUE(after[[length(after)]]$runnable))
})

test_that("plugin_dialog_preview renders a spec without a session", {
  spec <- plugin_dialog(
    "previewDemo", "Preview",
    ui = function(state, memory) htmltools::tags$p("Preview body"),
    on_ok = function(input, state) list()
  )
  html <- as.character(plugin_dialog_preview(spec))
  expect_match(html, "Preview body")
  expect_match(html, "rcmdr-plugin-preview")
  expect_error(plugin_dialog_preview(list()), "dialog specification")
})
