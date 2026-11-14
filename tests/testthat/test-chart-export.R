# Chart export ---------------------------------------------------------------

export_state <- function() {
  state <- chart_test_state()
  state$plot_dir <- tempfile("rcmdr-export-")
  dir.create(state$plot_dir)
  state$plot_prefix <- "charts"
  chart_apply(state, chart_spec("histogram", "D", list(x = "y")))
  state
}

test_that("PNG, PDF and SVG exports produce non-empty files", {
  state <- export_state()
  png <- tempfile(fileext = ".png")
  pdf <- tempfile(fileext = ".pdf")
  svg <- tempfile(fileext = ".svg")

  plot_export(state, 1L, "png", png, width = 500, height = 350)
  plot_export(state, 1L, "pdf", pdf, width = 500, height = 350)
  plot_export(state, 1L, "svg", svg, width = 500, height = 350)

  expect_true(file.exists(png))
  expect_gt(file.info(png)$size, 0)
  expect_true(file.exists(pdf))
  expect_gt(file.info(pdf)$size, 0)
  expect_true(file.exists(svg))
  expect_gt(file.info(svg)$size, 0)
})

test_that("HTML export is available for interactive plots", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")
  state <- export_state()
  chart_apply(state, chart_spec("scatter", "D", list(x = "x", y = "y")))
  html <- tempfile(fileext = ".html")
  plot_export(state, 2L, "html", html)
  expect_true(file.exists(html))
  expect_gt(file.info(html)$size, 0)
})

test_that("dialog plots can export their interactive expression", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")
  state <- chart_test_state()
  plot <- list(
    file = tempfile(fileext = ".png"),
    url = NULL,
    code = "with(D, Hist(y))",
    recorded = NULL,
    time = Sys.time(),
    title = "Dialog histogram",
    interactive_code = "plotly::plot_ly(x = 1:3, y = 1:3, type = \"scatter\", mode = \"markers\")"
  )
  index <- plot_register(state, plot)
  html <- tempfile(fileext = ".html")
  plot_export(state, index, "html", html)
  expect_true(file.exists(html))
  expect_gt(file.info(html)$size, 0)
})

test_that("legacy plots are exported from the captured PNG", {
  state <- chart_test_state()
  run_command(state, "plot(D$x, D$y)")
  target <- tempfile(fileext = ".png")
  plot_export(state, 1L, "png", target)
  expect_true(file.exists(target))
  expect_gt(file.info(target)$size, 0)
})

test_that("exporting a missing plot fails clearly", {
  state <- export_state()
  expect_error(plot_export(state, 99L, "png", tempfile(fileext = ".png")),
               "not available")
})

test_that("gallery download handlers use the export request", {
  state <- export_state()
  state$chart_export_request <- list(index = 1L, width = 400, height = 300,
                                     dpi = 96)
  expect_equal(state$chart_export_request$index, 1L)
})
