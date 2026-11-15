# ggplot2 engine: all chart types, extended mappings and shared options.

chart_gg_spec <- function(type, mapping = NULL, options = list(),
                          theme = list(), labels = list()) {
  defaults <- list(
    histogram = list(x = "y"),
    density = list(x = "y"),
    boxplot = list(x = "y"),
    scatter = list(x = "x", y = "y"),
    line = list(x = "x", y = c("y", "x")),
    bar = list(x = "g"),
    dot = list(x = "y"),
    strip = list(x = "y"),
    qq = list(x = "y"),
    means = list(x = "y", group = "g"),
    xyplot = list(x = "x", y = "y", group = "g")
  )
  chart_spec(
    type, "D", mapping %||% defaults[[type]], options = options,
    theme = utils::modifyList(list(engine = "ggplot2"), theme),
    labels = labels
  )
}

test_that("all chart types produce a ggplot2 command", {
  for (type in chart_type_ids()) {
    command <- chart_spec_command(chart_gg_spec(type))
    expect_match(command, "^print\\(ggplot2::ggplot\\(D", info = type)
    expect_match(command, "ggplot2::geom_|ggplot2::stat_", info = type)
    expect_false(grepl("palette(", command, fixed = TRUE), info = type)
    expect_false(grepl("par(", command, fixed = TRUE), info = type)
    expect_false(grepl("title(", command, fixed = TRUE), info = type)
  }
})

test_that("all ggplot2 specs validate", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  for (type in chart_type_ids()) {
    problems <- chart_spec_validate(chart_gg_spec(type), state)
    expect_equal(problems, character(), info = type)
  }
})

test_that("scatter smooth and labels are one valid expression", {
  spec <- chart_gg_spec(
    "scatter",
    mapping = list(x = "x", y = "y", group = "g", size = "y", label = "s"),
    options = list(smooth = TRUE, smooth_method = "loess", smooth_se = TRUE)
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::aes\\(x = x, y = y, colour = g, size = y\\)",
               fixed = FALSE)
  expect_match(command, "ggplot2::geom_smooth\\(method = \"loess\", se = TRUE\\)")
  expect_match(command, "ggplot2::geom_text\\(ggplot2::aes\\(label = s\\)")
  expect_false(grepl("ggplot\\(D, ggplot2::aes\\([^)]*\\), ggplot2::geom",
                     command))
})

test_that("facets, themes, scales and labels are emitted", {
  spec <- chart_gg_spec(
    "scatter",
    mapping = list(x = "x", y = "y", group = "g", facet = "g2"),
    options = list(flip = TRUE, log = "x", facet_scales = "free_x",
                   facet_ncol = 2),
    theme = list(ggplot_theme = "bw", grid = FALSE, legend = "bottom",
                 background = "#eeeeee", palette = "viridis"),
    labels = list(title = "T", subtitle = "S", x = "X", y = "Y",
                  caption = "C", tag = "A")
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::facet_wrap\\(ggplot2::vars\\(g2\\), scales = \"free_x\", ncol = 2\\)")
  expect_match(command, "ggplot2::theme_bw\\(base_size = 12\\)")
  expect_match(command, "panel.grid = ggplot2::element_blank\\(\\)")
  expect_match(command, "legend.position = \"bottom\"")
  expect_match(command, "plot.background = ggplot2::element_rect")
  expect_match(command, "ggplot2::scale_x_log10\\(\\)")
  expect_match(command, "ggplot2::scale_colour_manual")
  expect_match(command, "ggplot2::coord_flip\\(\\)")
  expect_match(command, "subtitle = \"S\"")
  expect_match(command, "tag = \"A\"")
  expect_match(command, "caption = \"C\"")
})

test_that("bar position and means error bars are mapped", {
  bar <- chart_gg_spec(
    "bar",
    mapping = list(x = "g", group = "g", facet = "g2"),
    options = list(position = "stack", alpha = 0.5)
  )
  command <- chart_spec_command(bar)
  expect_match(command, "position = \"stack\"")
  expect_match(command, "alpha = 0.5")

  means <- chart_gg_spec("means", options = list(error_bars = "sd"))
  expect_match(chart_spec_command(means), "fun.data = \"mean_sdl\"")
})

test_that("multi-series lines get one layer and a named palette", {
  spec <- chart_gg_spec(
    "line", mapping = list(x = "x", y = c("y", "x")),
    theme = list(palette = "tableau")
  )
  command <- chart_spec_command(spec)
  expect_equal(lengths(regmatches(command,
                                 gregexpr("geom_line", command))), 2L)
  expect_match(command, "scale_colour_manual\\(values = c\\(y = ")
})

test_that("base engine commands are unchanged by the ggplot2 options", {
  base <- chart_spec("histogram", "D", list(x = "y"))
  command <- chart_spec_command(base)
  expect_false(grepl("ggplot2::", command, fixed = TRUE))
  expect_match(command, "Hist\\(y")
})

test_that("ggplot2 validation catches wrong extended mappings", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()

  missing_facet <- chart_gg_spec(
    "scatter", mapping = list(x = "x", y = "y", facet = "notThere")
  )
  expect_match(chart_spec_validate(missing_facet, state), "Unknown variable")

  wrong_size <- chart_gg_spec(
    "scatter", mapping = list(x = "x", y = "y", size = "g")
  )
  expect_match(chart_spec_validate(wrong_size, state), "must be numeric")
})

test_that("every ggplot2 type previews without an error", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  for (type in chart_type_ids()) {
    preview <- chart_preview(state, chart_gg_spec(type), 400, 300)
    expect_identical(preview$type, "image", info = type)
    expect_null(preview$error, info = type)
  }
})

test_that("a ggplot2 chart applies and exports", {
  skip_if_not_installed("ggplot2")
  state <- chart_test_state()
  spec <- chart_gg_spec(
    "scatter", mapping = list(x = "x", y = "y", group = "g"),
    options = list(smooth = TRUE), labels = list(title = "Applied")
  )
  applied <- chart_apply(state, spec)
  expect_true(applied$ok)
  expect_true(grepl("ggplot2::ggplot", state$plots[[applied$index]]$code,
                    fixed = TRUE))

  file <- tempfile(fileext = ".png")
  on.exit(unlink(file), add = TRUE)
  plot_export(state, applied$index, "png", file, width = 500, height = 400)
  expect_true(file.exists(file))
  expect_gt(file.size(file), 0)
})

test_that("ggplot2 interactivity is gated on plotly compatibility", {
  spec <- chart_gg_spec("scatter")
  code <- chart_spec_interactive(spec)
  if (ggplotly_available()) {
    expect_match(code, "^plotly::ggplotly\\(ggplot2::ggplot", fixed = FALSE)
  } else {
    expect_null(code)
  }
})
