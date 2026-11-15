test_that("plugins extend menus, commands and dialogs", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  menus <- tempfile(fileext = ".txt")
  writeLines(c(
    '    menu    demoMenu        topMenu         ""                 ""          ""          ""',
    '    item    demoMenu        command         "Demo: Hello"       demoHello   ""          ""',
    '    item    demoMenu        command         "Demo: No args"     demoNoArgs  ""          ""',
    '    item    demoMenu        command         "Demo: Dialog"      demoDialog  ""          ""',
    '    item    topMenu         cascade         "Demo"              demoMenu    ""          ""'
  ), menus)
  on.exit(unlink(menus), add = TRUE)

  seen <- new.env()
  RcmdrShiny.plugin(
    name = "test-plugin",
    menus = menus,
    commands = list(
      demoHello = function(state) seen$hello <- TRUE,
      demoNoArgs = function() seen$noargs <- TRUE
    ),
    dialogs = list(
      demoDialog = plugin_dialog(
        "demoDialog", "Demo",
        ui = function(state, memory) htmltools::tags$p("demo"),
        on_ok = function(input, state) {
          list(commands = "1 + 1", memory = list(a = 1))
        }
      )
    )
  )

  leaves <- menu_leaves(menu_tree())
  expect_true(all(c("demoHello", "demoNoArgs", "demoDialog") %in%
                    leaves$command))
  expect_true("test-plugin" %in% list_plugins())

  state <- AppState(env = new.env())
  expect_equal(command_status(state, "demoHello"), "enabled")
  direct_commands()$demoHello(state)
  expect_true(seen$hello)
  direct_commands()$demoNoArgs(state)
  expect_true(seen$noargs)

  spec <- get_dialog_spec("demoDialog")
  expect_false(is.null(spec))
  expect_equal(spec$on_ok(list(), state)$commands, "1 + 1")

  html <- htmltools::renderTags(menu_ui(menu_tree(), function(node) {
    command_status(state, node$command, node$activation, node$install)
  }))$html
  expect_match(html, "Demo: Hello")
})

test_that("plugin scripts can be loaded from a file", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  menus <- tempfile(fileext = ".txt")
  writeLines(c(
    '    menu    scriptMenu      topMenu         ""                 ""          ""          ""',
    '    item    scriptMenu      command         "Script command"    scriptCmd   ""          ""',
    '    item    topMenu         cascade         "Script plugin"     scriptMenu  ""          ""'
  ), menus)
  script <- tempfile(fileext = ".R")
  writeLines(sprintf(
    "RcmdrShiny.plugin(name = 'script-plugin', menus = %s, commands = list(scriptCmd = function(state) invisible(NULL)))",
    deparse(menus)
  ), script)
  on.exit(unlink(c(menus, script)), add = TRUE)

  load_plugin(script)
  expect_true("script-plugin" %in% list_plugins())
  expect_true("scriptCmd" %in% names(direct_commands()))
  leaves <- menu_leaves(menu_tree())
  expect_true("scriptCmd" %in% leaves$command)
})

test_that("legacy Tk plugins are registered with a warning", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  expect_warning(
    RcmdrShiny.plugin(name = "legacy", tcltk = TRUE),
    "legacy Tk"
  )
  expect_true("legacy" %in% list_plugins())
})

test_that("a broken plugin does not abort the load", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  expect_no_error(load_plugins(list(
    "RcmdrShinyPlugin.NotInstalled",
    list(name = "probe-plugin",
         commands = list(probeCommand = function(state) invisible(NULL)))
  )))

  expect_true("probe-plugin" %in% list_plugins())
  failures <- plugin_failures()
  expect_equal(nrow(failures), 1L)
  expect_identical(failures$name, "RcmdrShinyPlugin.NotInstalled")
  expect_match(failures$message, "not installed", ignore.case = TRUE)
  expect_true("probeCommand" %in% names(plugin_commands()))

  health <- health_status()
  expect_equal(nrow(health$plugin_failures), 1L)

  report <- format_diagnostics(diagnostics_report())
  expect_true(any(grepl("Plugin failures", report, fixed = TRUE)))
})

test_that("a lazy plugin failure is recorded once and not retried", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)
  old <- getOption("RcmdrShiny.lazy_plugins")
  options(RcmdrShiny.lazy_plugins = TRUE)
  on.exit(options(RcmdrShiny.lazy_plugins = old), add = TRUE)

  load_plugins(list("RcmdrShinyPlugin.NotInstalled"))
  expect_length(plugins_pending(), 1L)

  invisible(plugin_commands())
  expect_length(plugins_pending(), 0L)
  expect_equal(nrow(plugin_failures()), 1L)

  invisible(plugin_commands())
  expect_equal(nrow(plugin_failures()), 1L)
})

test_that("the plugin loader asks for a page reload", {
  unload_plugins()
  path <- tempfile(fileext = ".rds")
  script <- tempfile(fileext = ".R")
  writeLines(
    "RcmdrShiny::RcmdrShiny.plugin(name = 'reload-probe')",
    script
  )
  on.exit({
    unlink(c(path, script))
    unload_plugins()
  }, add = TRUE)

  spec <- load_plugins_dialog()
  state <- AppState(env = new.env())
  state$options$preferences_file <- path
  result <- spec$on_ok(list(loadPlugins_file = script), state)

  expect_true("reload-probe" %in% list_plugins())
  expect_match(result$message, "Reload the page", fixed = TRUE)
})

test_that("startup plugins follow the saved selection", {
  expect_identical(resolve_startup_plugins(NULL, c("a", "b")), c("a", "b"))
  expect_identical(resolve_startup_plugins(character(), c("a", "b")),
                   character())
  expect_identical(resolve_startup_plugins("c", c("a", "b")), "c")
})

test_that("the plugin selection is persisted", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)

  state <- AppState(env = new.env())
  state$options$plugins <- c("RcmdrShinyPlugin.Export", "", "script.R")
  state$options$preferences_file <- path
  expect_true(preferences_save(state))

  restored <- AppState(env = new.env())
  restored$options$preferences_file <- path
  expect_true(preferences_load(restored))
  expect_identical(restored$options$plugins,
                   c("RcmdrShinyPlugin.Export", "script.R"))
})

test_that("the plugin manager saves the selection and loads the script", {
  unload_plugins()
  path <- tempfile(fileext = ".rds")
  script <- tempfile(fileext = ".R")
  writeLines(paste(
    "RcmdrShiny::RcmdrShiny.plugin(",
    "name = 'managed-plugin',",
    "commands = list(managedCommand = function(state) invisible(NULL)))"
  ), script)
  on.exit({
    unlink(c(path, script))
    unload_plugins()
  }, add = TRUE)

  state <- AppState(env = new.env())
  state$options$preferences_file <- path
  spec <- load_plugins_dialog()
  result <- spec$on_ok(
    list(loadPlugins_file = script, loadPlugins_remember = TRUE),
    state
  )

  expect_true("managed-plugin" %in% list_plugins())
  saved <- readRDS(path)
  expect_true(script %in% saved$plugins)
  expect_match(result$message, "saved", ignore.case = TRUE)
})

test_that("plugin conflicts are recorded and visible", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)

  RcmdrShiny.plugin("conflict-a",
                    commands = list(duplicatedCommand = function(state) NULL))
  expect_warning(
    RcmdrShiny.plugin("conflict-b",
                      commands = list(duplicatedCommand = function(state) NULL)),
    "overrides"
  )

  conflicts <- plugin_conflicts()
  expect_equal(nrow(conflicts), 1L)
  expect_identical(conflicts$plugin, "conflict-b")
  expect_identical(conflicts$kind, "commands")
  expect_match(conflicts$entries, "duplicatedCommand")

  health <- health_status()
  expect_equal(nrow(health$plugin_conflicts), 1L)
  expect_true(any(grepl("Plugin conflicts",
                        format_diagnostics(diagnostics_report()),
                        fixed = TRUE)))
})

test_that("deferred plugin loading records its materialisation time", {
  unload_plugins()
  on.exit(unload_plugins(), add = TRUE)
  old <- getOption("RcmdrShiny.lazy_plugins")
  options(RcmdrShiny.lazy_plugins = TRUE)
  on.exit(options(RcmdrShiny.lazy_plugins = old), add = TRUE)

  load_plugins(list(list(name = "deferred-probe",
                         commands = list(deferredCommand = function(state) NULL))))
  expect_length(plugins_pending(), 1L)
  invisible(plugin_commands())
  expect_length(plugins_pending(), 0L)
  expect_true(is.numeric(.plugin_registry$last_materialize_ms))
  expect_gte(health_status()$plugin_materialize_ms, 0)
})

test_that("the benchmark covers plugin loading", {
  skip_if_not("RcmdrShinyPlugin.Export" %in% installed_plugin_packages(),
              "RcmdrShinyPlugin.Export is not installed")
  row <- benchmark_plugin_load("RcmdrShinyPlugin.Export", "load 1 plugin")
  expect_s3_class(row, "data.frame")
  expect_identical(row$scenario, "load 1 plugin")
  expect_true(row$elapsed_ms >= 0)
})
