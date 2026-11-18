# Chart themes ---------------------------------------------------------------

test_that("palettes are emitted as reproducible commands", {
  expect_equal(
    chart_theme_prefix(chart_spec("histogram", "D", list(x = "y"),
                                  theme = list(palette = "tableau"))),
    cmd_set_palette(chart_palettes()$tableau)
  )
  expect_equal(
    chart_theme_prefix(chart_spec("histogram", "D", list(x = "y"))),
    character()
  )
})

test_that("background and base size become par settings", {
  prefix <- chart_theme_prefix(chart_spec(
    "histogram", "D", list(x = "y"),
    theme = list(background = "#101010", base_size = 14)
  ))
  expect_match(prefix, 'par\\(bg = "#101010", cex = 1.17\\)')
})

test_that("labels become a title call", {
  spec <- chart_spec("histogram", "D", list(x = "y"),
                     labels = list(title = "T", x = "X", y = "Y"))
  expect_equal(chart_label_commands(spec),
               'title(main = "T", xlab = "X", ylab = "Y")')
  expect_equal(chart_label_commands(chart_spec("histogram", "D",
                                               list(x = "y"))),
               character())
})

test_that("the ggplot2 theme is encoded in the command", {
  skip_if_not_installed("ggplot2")
  spec <- chart_spec(
    "bar", "D", list(x = "g", group = "g2"),
    theme = list(engine = "ggplot2", palette = "colorblind",
                 grid = FALSE, legend = "bottom",
                 background = "#ffffff", base_size = 14)
  )
  command <- chart_spec_command(spec)
  expect_match(command, "theme_minimal\\(base_size = 14\\)")
  expect_match(command, "panel.grid = ggplot2::element_blank\\(\\)")
  expect_match(command, 'legend.position = "bottom"')
  expect_match(command, "scale_fill_manual")
})

test_that("the selected palette reaches the applied command", {
  state <- chart_test_state()
  spec <- chart_spec("histogram", "D", list(x = "y", group = "g"),
                     theme = list(palette = "greys"))
  result <- chart_apply(state, spec)
  expect_true(result$ok)
  log <- paste(state$log, collapse = "\n")
  expect_match(log, "scale_fill_manual\\(values = c", perl = TRUE)
  expect_match(log, "#4D4D4D", fixed = TRUE)
})

test_that("white and its hex form are the same default surface", {
  expect_true(chart_background_is_white("white"))
  expect_true(chart_background_is_white("#FFFFFF"))
  expect_true(chart_background_is_white("#fff"))
  expect_false(chart_background_is_white("#fefefe"))
  expect_false(chart_background_is_white(""))

  plain <- chart_spec("histogram", "D", list(x = "y"))
  hex_white <- chart_spec("histogram", "D", list(x = "y"),
                          theme = list(background = "#ffffff"))
  # The colour picker returns hex, so the default command must not change.
  expect_equal(chart_spec_command(hex_white), chart_spec_command(plain))
  expect_equal(chart_theme_prefix(hex_white), chart_theme_prefix(plain))

  # A real colour is still emitted.
  dark <- chart_spec("histogram", "D", list(x = "y"),
                     theme = list(background = "#101010"))
  expect_match(chart_theme_prefix(dark), 'par\\(bg = "#101010"\\)')
  expect_match(chart_spec_command(dark), "plot.background")
})
