# Chart round-trip -----------------------------------------------------------

test_that("apply, reopen and apply again preserve and update the spec", {
  state <- chart_test_state()
  spec <- chart_spec(
    "scatter", "D", list(x = "x", y = "y"),
    options = list(smooth = TRUE),
    labels = list(title = "First")
  )
  first <- chart_apply(state, spec)
  expect_true(first$ok)

  reopened <- plot_reopen(state, first$index)
  expect_equal(reopened$type, "scatter")
  expect_equal(reopened$mapping$x, "x")
  expect_true(isTRUE(reopened$options$smooth))
  expect_equal(reopened$labels$title, "First")

  reopened$mapping$x <- "y"
  reopened$mapping$y <- "x"
  reopened$labels$title <- "Second"
  reopened$options$smooth <- FALSE
  second <- chart_apply(state, reopened)
  expect_true(second$ok)
  expect_equal(second$index, 2L)
  expect_equal(plot_title(state$plots[[2L]]), "Second")
  expect_equal(state$plots[[2L]]$spec$mapping$x, "y")
  expect_false(isTRUE(state$plots[[2L]]$spec$options$smooth))
})

test_that("legacy plots explain why they cannot be reopened", {
  state <- chart_test_state()
  run_command(state, "plot(D$x, D$y)")
  expect_null(plot_reopen(state, 1L))
})

test_that("a reopened spec keeps its theme and labels", {
  state <- chart_test_state()
  spec <- chart_spec(
    "histogram", "D", list(x = "y"),
    theme = list(palette = "viridis", base_size = 15, background = "#f0f0f0",
                 engine = "base"),
    labels = list(title = "T", x = "X", y = "Count", caption = "C")
  )
  index <- chart_apply(state, spec)$index
  reopened <- plot_reopen(state, index)
  expect_equal(reopened$theme$palette, "viridis")
  expect_equal(reopened$theme$base_size, 15)
  expect_equal(reopened$theme$background, "#f0f0f0")
  expect_equal(reopened$labels$caption, "C")
})
