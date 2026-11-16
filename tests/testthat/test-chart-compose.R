# Chart compositions --------------------------------------------------------

compose_children <- function() {
  list(
    chart_spec("histogram", "D", list(x = "y"), labels = list(title = "One")),
    chart_spec("bar", "D", list(x = "g"), labels = list(title = "Two"))
  )
}

test_that("a composition joins its children with patchwork", {
  skip_if_not_installed("patchwork")
  spec <- chart_spec(
    "compose", "D",
    options = list(children = compose_children(), layout = "1x2")
  )
  command <- chart_spec_command(spec)
  expect_match(command, "^print\\(", perl = TRUE)
  expect_match(command, "patchwork::plot_layout(guides = 'collect')",
               fixed = TRUE)
  expect_match(command, "patchwork::plot_annotation(tag_levels = 'A')",
               fixed = TRUE)
  expect_match(command, "ggplot2::geom_histogram", fixed = TRUE)
  expect_match(command, "ggplot2::geom_bar", fixed = TRUE)
})

test_that("layout presets shape the operator tree", {
  expressions <- c("a", "b", "c", "d")
  expect_equal(chart_compose_join(expressions[1:2], "1x2"), "(a) | (b)")
  expect_equal(chart_compose_join(expressions[1:2], "2x1"), "(a) / (b)")
  expect_equal(chart_compose_join(expressions[1:3], "1+2"),
               "(a) / ((b) | (c))")
  expect_equal(chart_compose_join(expressions, "2x2"),
               "((a) | (b)) / ((c) | (d))")
  expect_match(chart_compose_join(expressions[1:2], "wrap"),
               "patchwork::wrap_plots")
})

test_that("a composition needs at least two charts", {
  spec <- chart_spec(
    "compose", "D",
    options = list(children = list(compose_children()[[1L]]))
  )
  expect_match(chart_spec_validate(spec, chart_test_state()),
               "at least two charts")
  expect_error(chart_compose_object(spec), "at least two charts")
})

test_that("nested compositions are dropped from the children", {
  spec <- chart_spec(
    "compose", "D",
    options = list(
      children = c(compose_children(),
                   list(chart_spec("compose", "D", options = list()))),
      layout = "1x2"
    )
  )
  expect_length(chart_compose_children(spec), 2L)
})

test_that("a composition previews and applies", {
  skip_if_not_installed("patchwork")
  state <- chart_test_state()
  spec <- chart_spec(
    "compose", "D",
    options = list(children = compose_children(), layout = "1x2"),
    labels = list(title = "Combined")
  )
  preview <- chart_preview(state, spec, width = 480, height = 320)
  expect_equal(preview$type, "image", info = preview$error)
  result <- chart_apply(state, spec)
  expect_true(result$ok, info = result$error)
  expect_equal(length(state$plots), 1L)
})
