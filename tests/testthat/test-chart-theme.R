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
