# Applying a chart -----------------------------------------------------------

test_that("applying a chart logs the command and registers the plot", {
  state <- chart_test_state()
  spec <- chart_spec(
    "histogram", "D", list(x = "y"),
    labels = list(title = "Distribution")
  )
  result <- chart_apply(state, spec)
  expect_true(result$ok, info = result$error)
  expect_equal(result$index, 1L)
  expect_equal(length(state$plots), 1L)
  expect_true(any(grepl("Hist(y", state$log, fixed = TRUE)))

  plot <- state$plots[[1L]]
  expect_equal(plot$spec$type, "histogram")
  expect_equal(plot$spec$labels$title, "Distribution")
  expect_equal(plot_title(plot), "Distribution")
  expect_true("chart" %in% plot$tags)
  expect_true("histogram" %in% plot$tags)
  expect_equal(state$chart_last_spec$type, "histogram")

  entry <- state$history[[length(state$history)]]
  expect_equal(entry$source, "chart")
  expect_equal(entry$status, "ok")
})

test_that("an invalid chart never becomes a plot", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list(x = "g"))
  result <- chart_apply(state, spec)
  expect_false(result$ok)
  expect_match(result$error, "must be numeric")
  expect_equal(length(state$plots), 0L)
  expect_equal(length(state$log), 0L)
})

test_that("a failing command is reported and does not register a plot", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list(x = "y"))
  # Remove the variable after validation: the generated command must fail.
  spec$mapping$x <- "y"
  env <- state$env
  env$D$y <- NULL
  result <- chart_apply(state, spec)
  expect_false(result$ok)
  expect_equal(length(state$plots), 0L)
})

test_that("applying the same chart twice creates two gallery entries", {
  state <- chart_test_state()
  spec <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  first <- chart_apply(state, spec)
  second <- chart_apply(state, spec)
  expect_true(first$ok)
  expect_true(second$ok)
  expect_equal(length(state$plots), 2L)
  expect_false(identical(state$plots[[1L]]$id, state$plots[[2L]]$id))
})

test_that("applied charts keep the exact dialog command in the log", {
  state <- chart_test_state()
  spec <- chart_spec("boxplot", "D", list(x = "y", group = "g"),
                     labels = list(title = "By group"))
  result <- chart_apply(state, spec)
  expect_true(result$ok)
  log <- paste(state$log, collapse = "\n")
  expect_match(log, cmd_boxplot("D", "y", response = "y", group = "g"),
               fixed = TRUE)
  expect_match(log, 'title(main = "By group")', fixed = TRUE)
})
