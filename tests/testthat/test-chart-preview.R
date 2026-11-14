# Chart preview --------------------------------------------------------------

test_that("a valid preview produces an isolated PNG", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list(x = "y"))
  log_before <- state$log
  plots_before <- length(state$plots)

  result <- chart_preview(state, spec, width = 320, height = 240)
  expect_equal(result$type, "image")
  expect_true(file.exists(result$file))
  expect_gt(file.info(result$file)$size, 0)
  expect_null(result$error)
  expect_match(result$command, cmd_histogram("D", "y"), fixed = TRUE)

  expect_equal(state$log, log_before)
  expect_equal(length(state$plots), plots_before)
})

test_that("an invalid preview returns a readable error", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list())
  result <- chart_preview(state, spec)
  expect_equal(result$type, "error")
  expect_match(result$error, "required")
  expect_null(result$file)
})

test_that("previews are cached until the session changes", {
  state <- chart_test_state()
  chart_preview_cache_clear()
  spec <- chart_spec("histogram", "D", list(x = "y"))
  first <- chart_preview(state, spec, width = 320, height = 240)
  second <- chart_preview(state, spec, width = 320, height = 240)
  expect_identical(first$file, second$file)
  expect_equal(length(.chart_preview_cache$entries), 1L)

  run_command(state, "D$z <- D$y * 2")
  third <- chart_preview(state, spec, width = 320, height = 240)
  expect_false(identical(first$file, third$file))
})

test_that("the preview cache is bounded", {
  state <- chart_test_state()
  chart_preview_cache_clear()
  state$options$chart_preview_cache <- 2L
  for (value in c("x", "g", "s")) {
    spec <- chart_spec("bar", "D", list(x = "g"),
                       labels = list(title = value))
    chart_preview(state, spec, width = 300, height = 200)
  }
  expect_lte(length(.chart_preview_cache$entries), 2L)
})

test_that("plotly previews are built when the engine supports them", {
  skip_if_not_installed("plotly")
  state <- chart_test_state()
  spec <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  result <- chart_preview(state, spec, width = 320, height = 240)
  expect_equal(result$type, "image")
  expect_false(is.null(result$widget))
})

test_that("themes are reflected in the preview command", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list(x = "y"),
                     theme = list(palette = "tableau"))
  result <- chart_preview(state, spec, width = 320, height = 240)
  expect_match(result$command, "^palette\\(c\\(\"#4E79A7\"")
})
