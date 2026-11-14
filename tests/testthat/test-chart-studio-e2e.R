# Browser flow for the Chart Studio.
#
#   NOT_CRAN=true RCMDRSHINY_E2E=1 Rscript -e 'testthat::test_file("tests/testthat/test-chart-studio-e2e.R")'

chart_studio_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

chart_studio_switch_tab <- function(app, label) {
  app$run_js(sprintf(
    "Array.from(document.querySelectorAll('.nav-link')).find(function(a){return a.textContent.trim() === '%s';}).click();",
    label
  ))
  app$wait_for_idle(timeout = 30000)
}

test_that("the Chart Studio flow works in a browser", {
  chart_studio_ready()

  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    y = 1:6,
    x = 2 * (1:6),
    g = factor(c("a", "b", "a", "b", "a", "b"))
  )

  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "chart-studio-flow",
    width = 1400,
    height = 1100,
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
  app$set_inputs(selectActiveDataSet_dataset = "Dataset", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 60000)
  app$wait_for_idle()

  chart_studio_switch_tab(app, "Charts")
  app$wait_for_js("document.getElementById('chart_type') !== null",
                  timeout = 30000)

  # Build a histogram.
  app$set_inputs(
    chart_mode = "build", chart_type = "histogram",
    chart_dataset = "Dataset", wait_ = FALSE
  )
  app$wait_for_js("document.getElementById('chart_map_x') !== null",
                  timeout = 30000)
  app$set_inputs(chart_map_x = "y", wait_ = FALSE)
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('#chart_preview_image img') !== null",
    timeout = 30000
  )
  expect_match(app$get_text("#chart_command_text"), "Hist\\(y")
  expect_match(app$get_text("#chart_preview_message"), "isolated")

  app$click("chart_apply")
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('.rcmdr-chart-card') !== null || document.querySelector('#chart_mode') !== null",
    timeout = 30000
  )

  # Gallery: one card with a title and metadata.
  app$set_inputs(chart_mode = "gallery", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('.rcmdr-chart-card').length === 1",
    timeout = 30000
  )
  expect_match(app$get_text(".rcmdr-chart-card"), "Histogram of y")

  # Pin the chart.
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-chart-card a')).find(function(a){return a.textContent.trim() === 'Pin';}).click();"
  )
  app$wait_for_idle()
  app$wait_for_js(
    "document.querySelector('.rcmdr-chart-card.pinned') !== null",
    timeout = 30000
  )

  # Rename through the dialog runtime.
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-chart-card a')).find(function(a){return a.textContent.trim() === 'Detail';}).click();"
  )
  app$wait_for_idle()
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-chart-detail a')).find(function(a){return a.textContent.trim() === 'Rename';}).click();"
  )
  app$wait_for_js(
    "document.getElementById('chartRename_title') !== null",
    timeout = 30000
  )
  app$set_inputs(chartRename_title = "Distribution of y", wait_ = FALSE)
  app$click("dialog_ok")
  app$wait_for_js("document.querySelector('.modal') === null",
                  timeout = 30000)
  app$wait_for_idle()
  expect_match(app$get_text(".rcmdr-chart-detail"), "Distribution of y")

  # Reopen in the builder.
  app$run_js(
    "Array.from(document.querySelectorAll('.rcmdr-chart-detail a')).find(function(a){return a.textContent.trim() === 'Reopen in builder';}).click();"
  )
  app$wait_for_idle()
  app$wait_for_js(
    "document.getElementById('chart_title') !== null && document.getElementById('chart_title').value === 'Distribution of y'",
    timeout = 30000
  )
  expect_equal(app$get_value(input = "chart_map_x"), "y")

  # Export the applied chart as PNG.
  download <- app$get_download("chart_download_png")
  expect_true(file.exists(download))
  expect_gt(file.info(download)$size, 0)
})
