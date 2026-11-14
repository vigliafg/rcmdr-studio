# Chart type registry --------------------------------------------------------

test_that("every chart type has the metadata the builder needs", {
  types <- chart_types()
  expect_equal(sort(names(types)), sort(chart_type_ids()))
  for (id in names(types)) {
    info <- types[[id]]
    expect_true(nzchar(info$label))
    expect_true(is.list(info$mapping))
    expect_true(length(info$mapping) > 0L)
    expect_true(is.function(info$command))
    expect_true(nzchar(info$dialog))
    expect_true(is.function(info$dialog_memory))
    for (slot in names(info$mapping)) {
      rule <- info$mapping[[slot]]
      expect_true(nzchar(rule$label))
      expect_true(rule$kind %in% c("numeric", "factor", "any"))
    }
  }
})

test_that("each type produces a command and a valid spec", {
  state <- chart_test_state()
  mappings <- list(
    histogram = list(x = "y"),
    density = list(x = "y"),
    boxplot = list(x = "y", group = "g"),
    scatter = list(x = "x", y = "y"),
    line = list(x = "x", y = "y"),
    bar = list(x = "g"),
    dot = list(x = "y"),
    strip = list(x = "y"),
    qq = list(x = "y"),
    means = list(x = "y", group = "g"),
    xyplot = list(x = "x", y = "y")
  )
  for (id in names(mappings)) {
    spec <- chart_spec(id, "D", mappings[[id]])
    expect_true(chart_spec_ready(spec, state), info = id)
    expect_true(nzchar(chart_spec_command(spec)), info = id)
  }
})

test_that("interactive expressions are available for the plotly types", {
  state <- chart_test_state()
  supported <- c("histogram", "boxplot", "scatter", "line")
  for (id in chart_type_ids()) {
    info <- chart_type(id)
    if (id %in% supported) {
      expect_true(is.function(info$interactive), info = id)
    }
  }

  scatter <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  expect_match(chart_spec_interactive(scatter), "plotly::plot_ly")
  expect_match(chart_spec_interactive(scatter), "event_register\\(\"plotly_selected\"\\)")

  histogram <- chart_spec("histogram", "D", list(x = "y"))
  expect_match(chart_spec_interactive(histogram), "type = \"histogram\"")
})

test_that("mapping choices follow the declared kind", {
  state <- chart_test_state()
  numeric_rule <- list(kind = "numeric")
  factor_rule <- list(kind = "factor")
  any_rule <- list(kind = "any")

  expect_equal(chart_mapping_choices(state, numeric_rule), c("y", "x"))
  expect_equal(chart_mapping_choices(state, factor_rule), c("g", "g2", "s"))
  expect_equal(chart_mapping_choices(state, any_rule),
               c("y", "x", "g", "g2", "s"))
})

test_that("mapping controls render selectors for every required slot", {
  state <- chart_test_state()
  spec <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  html <- htmltools::renderTags(
    chart_mapping_controls(state, spec)
  )$html
  expect_match(html, "chart_map_x")
  expect_match(html, "chart_map_y")
  expect_match(html, "chart_map_group")

  bar <- chart_spec("bar", "D", list(x = "g"))
  html <- htmltools::renderTags(chart_mapping_controls(state, bar))$html
  expect_match(html, "chart_map_x")
  expect_false(grepl("chart_map_y", html, fixed = TRUE))
})

test_that("type choices are labelled and stable", {
  choices <- chart_type_choices()
  expect_equal(unname(choices), chart_type_ids())
  expect_true(all(nzchar(names(choices))))
  expect_equal(chart_type("histogram")$label, "Histogram")
  expect_null(chart_type("unknown"))
})

test_that("dialog memory matches the existing dialogs", {
  state <- chart_test_state()
  specs <- list(
    histogram = chart_spec("histogram", "D", list(x = "y", group = "g")),
    boxplot = chart_spec("boxplot", "D", list(x = "y", group = "g")),
    scatter = chart_spec("scatter", "D", list(x = "x", y = "y")),
    means = chart_spec("means", "D", list(x = "y", group = "g"))
  )
  memory <- chart_type("histogram")$dialog_memory(specs$histogram)
  expect_equal(memory$variable, "y")
  expect_equal(memory$group, "g")

  memory <- chart_type("scatter")$dialog_memory(specs$scatter)
  expect_equal(memory$x, "x")
  expect_equal(memory$y, "y")

  memory <- chart_type("boxplot")$dialog_memory(specs$boxplot)
  expect_equal(memory$variables, "y")
  expect_equal(memory$response, "y")
  expect_equal(memory$group, "g")

  memory <- chart_type("means")$dialog_memory(specs$means)
  expect_equal(memory$response, "y")
  expect_equal(memory$group, "g")
})
