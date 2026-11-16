# Chart specification --------------------------------------------------------

test_that("chart specs have stable defaults", {
  spec <- chart_spec("histogram", "D", list(x = "y"))
  expect_s3_class(spec, "RcmdrChartSpec")
  expect_equal(spec$version, 1L)
  expect_equal(spec$type, "histogram")
  expect_equal(spec$mapping$x, "y")
  expect_null(spec$mapping$group)
  expect_equal(spec$options$scale, "frequency")
  expect_equal(spec$options$breaks, "Sturges")
  expect_equal(spec$theme$engine, "ggplot2")
  expect_equal(spec$theme$palette, "default")
  expect_equal(spec$labels$title, "")
  expect_equal(spec$size$width, 800L)
  expect_error(chart_spec("unknown", "D"), "Unknown chart type")
})

test_that("every chart type produces a ggplot2 command", {
  types <- setdiff(chart_type_ids(), c(chart_stat_type_ids(), "compose"))
  for (type in types) {
    info <- chart_type(type)
    mapping <- lapply(names(info$mapping %||% list()), function(slot) {
      rule <- info$mapping[[slot]]
      if (isTRUE(rule$optional)) return(NULL)
      switch(rule$kind %||% "any", numeric = "y", factor = "g", "y")
    })
    names(mapping) <- names(info$mapping %||% list())
    mapping <- Filter(Negate(is.null), mapping)
    spec <- chart_spec(type, "D", mapping)
    command <- chart_spec_command(spec)
    expect_match(command, "^print\\(ggplot2::", info = type)
  }
})

test_that("theme and labels are emitted in the ggplot2 command", {
  spec <- chart_spec(
    "histogram", "D", list(x = "y", group = "g"),
    theme = list(palette = "colorblind", background = "#f5f5f5",
                 base_size = 14, ggplot_theme = "bw"),
    labels = list(title = "Distribution", x = "Value", y = "Count",
                  caption = "Session data")
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::theme_bw\\(base_size = 14\\)")
  expect_match(command, "ggplot2::scale_fill_manual")
  expect_match(command, "#0072B2", fixed = TRUE)
  expect_match(command, "plot.background = ggplot2::element_rect",
               fixed = TRUE)
  expect_match(command, 'title = "Distribution"', fixed = TRUE)
  expect_match(command, 'x = "Value"', fixed = TRUE)
  expect_match(command, 'caption = "Session data"', fixed = TRUE)
})

test_that("colour-blind and custom palettes are available", {
  palettes <- chart_palettes()
  expect_true(all(c("default", "colorblind", "tableau", "viridis", "greys")
                  %in% names(palettes)))
  expect_null(chart_palette_colors("default"))
  expect_equal(length(chart_palette_colors("colorblind")), 8L)
  expect_equal(length(chart_palette_colors("greys")), 8L)
  expect_equal(unname(chart_palette_choices()),
               names(chart_palettes()))
})

test_that("validation reports missing mappings and wrong variable types", {
  state <- chart_test_state()

  missing <- chart_spec("histogram", "D", list())
  expect_match(chart_spec_validate(missing, state), "required")

  wrong <- chart_spec("histogram", "D", list(x = "g"))
  expect_match(chart_spec_validate(wrong, state), "must be numeric")

  wrong_group <- chart_spec("histogram", "D", list(x = "y", group = "x"))
  expect_match(chart_spec_validate(wrong_group, state), "must be a factor")

  unknown <- chart_spec("histogram", "D", list(x = "missing"))
  expect_true(any(grepl("Unknown variable", chart_spec_validate(unknown, state))))

  expect_match(chart_spec_validate(chart_spec("histogram", "Nope",
                                              list(x = "y")), state),
               "not available")

  expect_true(chart_spec_ready(chart_spec("histogram", "D", list(x = "y")),
                               state))
})

test_that("the ggplot2 engine produces a reproducible print command", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  spec <- chart_spec(
    "scatter", "D", list(x = "x", y = "y", group = "g"),
    theme = list(engine = "ggplot2", palette = "colorblind"),
    labels = list(title = "Relationship", x = "X", y = "Y")
  )
  expect_true(chart_spec_ready(spec, state))
  command <- chart_spec_command(spec)
  expect_match(command, "print\\(ggplot2::ggplot\\(D")
  expect_match(command, "ggplot2::geom_point")
  expect_match(command, "scale_colour_manual")
  expect_match(command, "theme_minimal\\(base_size = 12\\)")
  expect_match(command, 'title = "Relationship"')
})

test_that("ggplot2 grouped histograms keep the fill mapping", {
  skip_if_not_installed("ggplot2")
  spec <- chart_spec(
    "histogram", "D", list(x = "y", group = "g"),
    theme = list(engine = "ggplot2", palette = "tableau")
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::aes\\(x = y, fill = g\\)")
  expect_false(grepl('fill = "#4E79A7"', command, fixed = TRUE))
  expect_match(command, "scale_fill_manual")
  expect_match(command, "position = \"identity\"")
})

test_that("every chart type has a ggplot2 engine", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  for (id in chart_type_ids()) {
    if (!chart_type_available(id, "ggplot2")) next
    # Compositions and statistical charts have their own generators.
    if (identical(id, "compose") || chart_stat_type(id)) next
    info <- chart_type(id)
    mapping <- lapply(names(info$mapping), function(slot) {
      rule <- info$mapping[[slot]]
      if (isTRUE(rule$optional)) "" else if (identical(rule$kind, "numeric")) {
        "y"
      } else if (identical(rule$kind, "factor")) {
        "g"
      } else {
        "x"
      }
    })
    names(mapping) <- names(info$mapping)
    spec <- chart_spec(id, "D", mapping, theme = list(engine = "ggplot2"))
    expect_true(chart_spec_ready(spec, state), info = id)
    expect_match(chart_spec_command(spec), "print\\(ggplot2::ggplot",
                 info = id)
  }
})

test_that("chart titles are derived from mappings", {
  expect_equal(chart_spec_title(chart_spec("histogram", "D",
                                          list(x = "y"))),
               "Histogram of y")
  expect_equal(chart_spec_title(chart_spec("scatter", "D",
                                          list(x = "x", y = "y"))),
               "y versus x")
  expect_equal(chart_spec_title(chart_spec("boxplot", "D",
                                          list(x = "y", group = "g"))),
               "Boxplot of y by g")
  spec <- chart_spec("histogram", "D", list(x = "y"),
                     labels = list(title = "Custom"))
  expect_equal(plot_title(list(spec = spec)), "Custom")
})
