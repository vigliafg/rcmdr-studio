# Browser flow for the plugin manager: open it, select an installed plugin,
# apply, and check that the selection is written to the preferences.
#
#   RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-plugin-manager-e2e.R")'

manager_e2e_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

test_that("the plugin manager saves the selected plugin", {
  manager_e2e_ready()
  installed <- RcmdrShiny:::installed_plugin_packages()
  skip_if(length(installed) == 0L, "no RcmdrShiny plugin package is installed")
  package <- if ("RcmdrShinyPlugin.Export" %in% installed) {
    "RcmdrShinyPlugin.Export"
  } else {
    installed[[1L]]
  }

  preferences <- tempfile(fileext = ".rds")
  old_preferences <- Sys.getenv("RCMDRSHINY_PREFERENCES", unset = NA_character_)
  Sys.setenv(RCMDRSHINY_PREFERENCES = preferences)
  on.exit({
    unlink(preferences)
    if (is.na(old_preferences)) {
      Sys.unsetenv("RCMDRSHINY_PREFERENCES")
    } else {
      Sys.setenv(RCMDRSHINY_PREFERENCES = old_preferences)
    }
  }, add = TRUE)

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = new.env()),
    name = "plugin-manager-flow",
    width = 1400,
    height = 1000,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_idle(timeout = 30000)
  app$run_js("Shiny.setInputValue('tour_skip', 1, {priority: 'event'});")
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
  key <- leaves$key[leaves$command == "loadPlugins"][[1L]]
  expect_gt(length(key), 0L)
  app$run_js(sprintf("document.getElementById(%s).click();",
                     jsonlite::toJSON(key, auto_unbox = TRUE)))
  app$wait_for_js("document.querySelector('.modal') !== null", timeout = 30000)
  expect_match(app$get_text(".modal-title"), "Manage", fixed = TRUE)

  checkbox <- paste0("loadPlugins_plugins_", package)
  app$wait_for_js(
    sprintf("document.getElementById(%s) !== null",
            jsonlite::toJSON(checkbox, auto_unbox = TRUE)),
    timeout = 30000
  )
  app$run_js(sprintf("document.getElementById(%s).click();",
                     jsonlite::toJSON(checkbox, auto_unbox = TRUE)))
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)

  saved <- NULL
  for (i in seq_len(50L)) {
    if (file.exists(preferences)) {
      saved <- tryCatch(readRDS(preferences), error = function(e) NULL)
      if (is.list(saved) && package %in% (saved$plugins %||% character())) break
    }
    Sys.sleep(0.2)
  }
  expect_true(is.list(saved))
  expect_true(package %in% saved$plugins)
})
