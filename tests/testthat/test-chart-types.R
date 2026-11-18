# Chart type registry --------------------------------------------------------

test_that("every chart type has the metadata the builder needs", {
  types <- chart_types()
  expect_equal(sort(names(types)), sort(chart_type_ids()))
  for (id in names(types)) {
    info <- types[[id]]
    expect_true(nzchar(info$label))
    expect_true(is.list(info$mapping))
    if (!identical(id, "compose")) {
      expect_true(length(info$mapping) > 0L, info = id)
    }
    if ("base" %in% chart_type_engines(info)) {
      expect_true(is.function(info$command), info = id)
      expect_true(nzchar(info$dialog), info = id)
      expect_true(is.function(info$dialog_memory), info = id)
    }
    for (slot in names(info$mapping)) {
      rule <- info$mapping[[slot]]
      expect_true(nzchar(rule$label))
      expect_true(rule$kind %in% c("numeric", "factor", "any", "model"),
                  info = id)
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

test_that("interactive expressions are built from the ggplot2 object", {
  state <- chart_test_state()
  scatter <- chart_spec("scatter", "D", list(x = "x", y = "y"))
  code <- chart_spec_interactive(scatter)
  if (is.null(code)) {
    # plotly cannot convert this ggplot2 version: the Studio hides the widget.
    expect_false(ggplotly_available())
  } else {
    expect_match(code, "plotly::ggplotly\\(", perl = TRUE)
  }

  composed <- chart_spec("compose", "D")
  expect_null(chart_spec_interactive(composed))
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
  # The mapping uses the searchable picker, not a selectize tag field.
  expect_match(html, "virtual-select", fixed = TRUE)
  expect_false(grepl("selectize-control", html, fixed = TRUE))

  bar <- chart_spec("bar", "D", list(x = "g"))
  html <- htmltools::renderTags(chart_mapping_controls(state, bar))$html
  expect_match(html, "chart_map_x")
  expect_false(grepl("chart_map_y", html, fixed = TRUE))
})

test_that("type choices are labelled and stable", {
  choices <- chart_type_choices()
  # Types whose optional extension is missing are hidden from the selector.
  available <- chart_type_ids()[vapply(chart_type_ids(), chart_type_available,
                                       logical(1))]
  expect_setequal(unname(choices), available)
  expect_true(all(nzchar(names(choices))))
  expect_equal(chart_type("histogram")$label, "Histogram")
  expect_null(chart_type("unknown"))

  base <- chart_type_choices("base")
  expect_true("histogram" %in% unname(base))
  expect_false("violin" %in% unname(base))
  ggplot <- chart_type_choices("ggplot2")
  expect_true(all(c("violin", "ecdf", "density_2d", "heatmap") %in%
                    unname(ggplot)))
  expect_true(chart_type_available("histogram", "base"))
  expect_false(chart_type_available("violin", "base"))
  expect_true(chart_type_available("violin", "ggplot2"))
  expect_match(chart_type("violin")$engines, "ggplot2")
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

test_that("every type declares its option groups without losing a field", {
  for (name in names(chart_types_core())) {
    info <- chart_type(name)
    defaults <- names(info$defaults %||% list())
    groups <- chart_option_groups(info)
    expect_gt(length(groups), 0L)
    values <- unlist(groups, use.names = FALSE)
    # Every option belongs to exactly one group: a typo in the metadata must
    # not hide a control, and no control may appear in two panels.
    expect_setequal(values, defaults)
    expect_equal(length(values), length(defaults), info = name)
    expect_true(all(vapply(groups, length, integer(1)) > 0L), info = name)
  }

  # A type without metadata still gets one group.
  plain <- list(defaults = list(one = 1, two = 2), controls = function(spec) NULL)
  expect_equal(chart_option_groups(plain), list(Options = c("one", "two")))
  # Unknown names are dropped and orphans join the first group.
  odd <- list(defaults = list(a = 1, b = 2, c = 3),
              option_groups = list(Pair = c("a", "typo")))
  expect_equal(chart_option_groups(odd),
               list(Pair = c("a", "b", "c")))
})

test_that("splitting the controls keeps every per-type field once", {
  ids_of <- function(tags) {
    html <- paste(unlist(lapply(as.list(tags), as.character)), collapse = "")
    regmatches(html, gregexpr('id="chart_opt_[A-Za-z0-9_]+"', html))[[1]]
  }
  for (name in chart_type_ids()) {
    info <- chart_type(name)
    if (is.null(info)) next
    spec <- chart_spec(name, "Dataset", list())
    flat <- ids_of(Filter(Negate(is.null), as.list(info$controls(spec))))
    grouped <- chart_option_controls(info, spec)

    expect_equal(names(grouped), names(chart_option_groups(info)))
    together <- do.call(c, lapply(grouped, as.list))
    grouped_ids <- ids_of(together)
    expect_setequal(grouped_ids, flat)
    expect_equal(length(grouped_ids), length(flat), info = name)
    expect_equal(anyDuplicated(grouped_ids), 0L, info = name)
  }
})
