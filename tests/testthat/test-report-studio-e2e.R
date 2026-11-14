# Browser flow for the Report Studio.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-report-studio-e2e.R")'

report_studio_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

report_switch_tab <- function(app, label) {
  app$run_js(sprintf(
    "Array.from(document.querySelectorAll('.nav-link')).find(function(a){return a.textContent.trim() === '%s';}).click();",
    label
  ))
  app$wait_for_idle(timeout = 30000)
}

report_editor_value <- function(app) {
  app$get_js(
    "ace.edit(document.querySelector('#report_editor_ui .ace_editor')).getValue()"
  )
}

test_that("the Report Studio flow works in a browser", {
  report_studio_ready()

  env <- new.env()
  env$D <- data.frame(
    y = 1:6,
    x = c(2, 4, 6, 8, 10, 12),
    g = factor(rep(c("a", "b"), 3))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "report-studio-flow",
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

  report_switch_tab(app, "Report")
  app$wait_for_js(
    "document.querySelector('#report_editor_ui .ace_editor') !== null",
    timeout = 60000
  )

  # Create a report from the analysis template.
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-template-card')).find(function(a){return a.textContent.indexOf('Analysis report') >= 0;}).click();"
  )
  app$wait_for_js(
    "ace.edit(document.querySelector('#report_editor_ui .ace_editor')).getValue().indexOf('## Context') >= 0",
    timeout = 60000
  )
  expect_match(report_editor_value(app), "summary\\(D\\)")
  app$wait_for_js(
    "document.querySelector('.rcmdr-report-outline') && document.querySelector('.rcmdr-report-outline').innerText.indexOf('Context') >= 0",
    timeout = 60000
  )
  expect_match(app$get_text(".rcmdr-report-outline"), "Context")

  # Create a plot from the Console, without changing the report mode.
  report_switch_tab(app, "Console")
  app$wait_for_js("document.getElementById('console_input') !== null",
                  timeout = 60000)
  app$set_inputs(console_input = "with(D, plot(y ~ x))", wait_ = FALSE)
  app$click("console_run")
  app$wait_for_idle(timeout = 60000)

  # Insert the last plot into the report.
  report_switch_tab(app, "Report")
  app$wait_for_js(
    "document.getElementById('report_plot_id') !== null && document.getElementById('report_plot_id').options.length > 0",
    timeout = 60000
  )
  value <- app$get_js(
    "document.getElementById('report_plot_id').options[document.getElementById('report_plot_id').selectedIndex].value"
  )
  app$set_inputs(report_plot_id = value, wait_ = FALSE)
  app$wait_for_idle()
  app$run_js("document.querySelector('.rcmdr-report-insert').open = true;")
  app$run_js("document.getElementById('report_insert_plot').click();")
  app$wait_for_idle()
  app$wait_for_js(
    "ace.edit(document.querySelector('#report_editor_ui .ace_editor')).getValue().indexOf('include_graphics') >= 0",
    timeout = 60000
  )

  # Run the summary cell from its card and insert its output.
  app$wait_for_js(
    "Array.from(document.querySelectorAll('.rcmdr-cell-card')).some(function(c){return c.innerText.indexOf('summary') >= 0;})",
    timeout = 60000
  )
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-cell-card')).find(function(c){return c.innerText.indexOf('summary') >= 0;}).querySelector('a').click();"
  )
  app$wait_for_idle(timeout = 60000)
  app$wait_for_js(
    "Array.from(document.querySelectorAll('.rcmdr-cell-card')).some(function(c){return c.innerText.indexOf('summary') >= 0 && c.innerText.indexOf('ok') >= 0;})",
    timeout = 60000
  )
  app$run_js("document.getElementById('report_insert_output').click();")
  app$wait_for_idle()
  app$wait_for_js(
    "ace.edit(document.querySelector('#report_editor_ui .ace_editor')).getValue().indexOf('### Output') >= 0",
    timeout = 60000
  )

  # The fast preview is Markdown, not a knit.
  app$set_inputs(report_preview_mode = "markdown", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelector('.rcmdr-report-preview').innerText.indexOf('Context') >= 0",
    timeout = 60000
  )

  # Knit to HTML and show it.
  skip_if_not(RcmdrShiny:::document_format_available("html", "rmd"),
              "Pandoc or rmarkdown not available")
  app$set_inputs(report_knit_format = "html", wait_ = FALSE)
  app$click("report_knit")
  app$wait_for_js(
    "document.querySelector('.rcmdr-knit-entry') !== null",
    timeout = 180000
  )
  app$set_inputs(report_preview_mode = "html", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelector('.rcmdr-report-preview iframe') !== null",
    timeout = 120000
  )

  download <- app$get_download("report_download_knit")
  expect_true(file.exists(download))
  expect_gt(file.info(download)$size, 0)
  expect_match(tools::file_ext(download), "html")
})
