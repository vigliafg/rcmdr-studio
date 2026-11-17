# Browser flow for the Workbench.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-workbench-e2e.R")'

workbench_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

workbench_switch_tab <- function(app, label) {
  switch_main_tab(app, label)
}

test_that("the Workbench flow works in a browser", {
  workbench_ready()

  env <- new.env()
  env$D <- data.frame(
    y = c(2, 1, 4, 3, 7, 6, 9, 8),
    x = c(2, 4, 6, 8, 10, 12, 14, 16),
    g = factor(rep(c("a", "b"), 4))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "workbench-flow",
    width = 1500,
    height = 1200,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)

  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-menu-item').length > 0",
    timeout = 60000
  )

  leaves <- RcmdrShiny::menu_leaves(RcmdrShiny::menu_tree())
  key <- leaves$key[leaves$command == "selectActiveDataSet"][[1L]]
  app$run_js(sprintf("document.getElementById('%s').click();", key))
  app$wait_for_js(
    "document.getElementById('selectActiveDataSet_dataset') !== null",
    timeout = 60000
  )
  app$set_inputs(selectActiveDataSet_dataset = "D", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)
  app$wait_for_idle()

  # Console: type a command, run it, check the card and the history.
  workbench_switch_tab(app, "Console")
  app$wait_for_js("document.getElementById('console_input') !== null",
                  timeout = 60000)
  app$set_inputs(console_input = "summary(D)", wait_ = FALSE)
  app$click("console_run")
  app$wait_for_js(
    "document.querySelector('.rcmdr-console-log .rcmdr-history-card') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-console-log"), "summary\\(D\\)")
  expect_match(app$get_text("#console_status_ui"), "OK|Ready")

  # Rerun from the card.
  app$run_js(
    "document.querySelector('.rcmdr-console-log .rcmdr-history-card [data-history-action=\"rerun\"]').click();"
  )
  app$wait_for_idle(timeout = 60000)
  expect_match(app$get_text(".rcmdr-console-log"), "summary\\(D\\)")

  # Output cards with search.
  app$run_js(
    "Array.from(document.querySelectorAll('#console_tabs .nav-link')).find(function(a){return a.textContent.trim() === 'Output';}).click();"
  )
  app$wait_for_js("document.getElementById('output_filter') !== null",
                  timeout = 60000)
  app$set_inputs(output_filter = "summary", wait_ = FALSE)
  app$wait_for_idle()
  expect_match(app$get_text(".rcmdr-history-card"), "summary\\(D\\)")

  # Messages: generate a warning and filter by severity.
  app$run_js(
    "Array.from(document.querySelectorAll('#console_tabs .nav-link')).find(function(a){return a.textContent.trim() === 'Console';}).click();"
  )
  app$wait_for_js("document.getElementById('console_input') !== null",
                  timeout = 60000)
  app$set_inputs(console_input = "warning('careful')", wait_ = FALSE)
  app$click("console_run")
  app$wait_for_idle(timeout = 60000)
  app$run_js(
    "Array.from(document.querySelectorAll('#console_tabs .nav-link')).find(function(a){return a.textContent.trim() === 'Messages';}).click();"
  )
  app$wait_for_js("document.getElementById('messages_severity') !== null",
                  timeout = 60000)
  app$set_inputs(messages_severity = "warning", wait_ = FALSE)
  app$wait_for_idle()
  expect_match(app$get_text(".rcmdr-message-text"), "careful")

  # Environment: preview the data set and open its registry view.
  workbench_switch_tab(app, "Environment")
  app$wait_for_js("document.getElementById('environment_filter') !== null",
                  timeout = 60000)
  expect_match(app$get_text(".rcmdr-object-table"), "D")
  app$run_js(
    "Shiny.setInputValue('environment_action', {name: 'D', action: 'preview'}, {priority: 'event'});"
  )
  app$wait_for_js(
    "document.querySelector('.rcmdr-object-preview') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-object-preview"), "data.frame")

  app$run_js(
    "Array.from(document.querySelectorAll('#environment_tabs .nav-link')).find(function(a){return a.textContent.trim() === 'Data sets';}).click();"
  )
  app$wait_for_js(
    "document.querySelector('.table') && document.querySelector('.table').innerText.indexOf('D') >= 0",
    timeout = 60000
  )

  # Fit a model from the console, then use the Models dashboard.
  workbench_switch_tab(app, "Console")
  app$wait_for_js("document.getElementById('console_input') !== null",
                  timeout = 60000)
  app$set_inputs(console_input = "fit <- lm(y ~ x, data = D)", wait_ = FALSE)
  app$click("console_run")
  app$wait_for_idle(timeout = 60000)

  workbench_switch_tab(app, "Environment")
  app$wait_for_js("document.getElementById('environment_tabs') !== null",
                  timeout = 60000)
  app$run_js(
    "Array.from(document.querySelectorAll('#environment_tabs .nav-link')).find(function(a){return a.textContent.trim() === 'Models';}).click();"
  )
  app$wait_for_js(
    "document.querySelector('.rcmdr-models-table') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-models-table"), "fit")

  app$run_js(
    "Shiny.setInputValue('model_action', {name: 'fit', action: 'select'}, {priority: 'event'});"
  )
  app$wait_for_js(
    "document.body.innerText.indexOf('Reopen dialog') >= 0",
    timeout = 60000
  )
  app$run_js(
    "Shiny.setInputValue('model_action', {name: 'fit', action: 'summary'}, {priority: 'event'});"
  )
  app$wait_for_idle(timeout = 60000)
  expect_match(app$get_text(".rcmdr-models-table"), "fit")

  # Script cells: run the first cell and show its inline output.
  workbench_switch_tab(app, "Script")
  app$wait_for_js(
    "document.querySelector('#script_editor_ui .ace_editor') !== null",
    timeout = 60000
  )
  app$wait_for_js("document.querySelector('.rcmdr-doc-tabs') !== null",
                  timeout = 60000)
  app$run_js(
    "var e = ace.edit(document.querySelector('#script_editor_ui .ace_editor')); e.setValue('mean(D$y)\\n'); e.gotoLine(1, 0); e.focus();"
  )
  app$wait_for_js(
    "String(Shiny.shinyapp.$inputValues.script || '').indexOf('mean(D$y)') >= 0",
    timeout = 60000
  )
  app$wait_for_idle()
  app$click("run_cell")
  app$wait_for_js(
    "document.querySelector('.rcmdr-script-output') !== null",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-script-output"), "5")
})
