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

test_that("the ggplot2 boxplot maps notch, width, outliers and jitter", {
  spec <- chart_gg_spec(
    "boxplot",
    mapping = list(x = "y", group = "g", facet = "g2"),
    options = list(notch = TRUE, notchwidth = 0.4, varwidth = TRUE,
                   outline = FALSE, width = 0.6, horizontal = TRUE,
                   jitter = 0.1)
  )
  command <- chart_spec_command(spec)
  expect_match(command, "notch = TRUE")
  expect_match(command, "notchwidth = 0.4")
  expect_match(command, "varwidth = TRUE")
  expect_match(command, "width = 0.6")
  expect_match(command, "outlier.shape = NA")
  expect_match(command, "ggplot2::geom_jitter\\(width = 0.1")
  expect_match(command, "ggplot2::coord_flip\\(\\)")
  expect_match(command, "facet_wrap")
})

test_that("the ggplot2 histogram maps the base scale to after_stat", {
  counts <- chart_spec_command(chart_gg_spec("histogram",
                                             options = list(scale = "frequency")))
  expect_false(grepl("after_stat", counts, fixed = TRUE))

  density <- chart_spec_command(chart_gg_spec("histogram",
                                              options = list(scale = "density")))
  expect_match(density, "ggplot2::after_stat\\(density\\)")

  percent <- chart_spec_command(chart_gg_spec("histogram",
                                              options = list(scale = "percent")))
  expect_match(percent, "after_stat\\(count / sum\\(count\\) \\* 100\\)")
})

test_that("the ggplot2 scatterplot maps regression bands and ellipses", {
  spec <- chart_gg_spec(
    "scatter",
    mapping = list(x = "x", y = "y", group = "g"),
    options = list(regression = TRUE, smooth_se = TRUE, ellipse = TRUE)
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::geom_smooth\\(method = \"lm\", se = TRUE\\)")
  expect_match(command, "ggplot2::stat_ellipse\\(\\)")

  loess <- chart_gg_spec(
    "scatter", options = list(smooth = TRUE, smooth_method = "loess",
                              smooth_se = FALSE)
  )
  expect_match(chart_spec_command(loess),
               "ggplot2::geom_smooth\\(method = \"loess\", se = FALSE\\)")
})

test_that("the remaining ggplot types map their options", {
  density <- chart_gg_spec(
    "density", options = list(adjust = 0.8)
  )
  expect_match(chart_spec_command(density), "adjust = 0.8")

  line <- chart_gg_spec(
    "line", mapping = list(x = "x", y = "y", group = "g"),
    options = list(line_type = "step", linetype = "dashed", linewidth = 1.5)
  )
  command <- chart_spec_command(line)
  expect_match(command, "ggplot2::geom_step")
  expect_match(command, "colour = g, group = g")
  expect_match(command, "linetype = \"dashed\"")
  expect_match(command, "linewidth = 1.5")

  area <- chart_gg_spec("line", options = list(line_type = "area"))
  expect_match(chart_spec_command(area), "ggplot2::geom_area")

  bar <- chart_gg_spec(
    "bar", mapping = list(x = "g", group = "g2"),
    options = list(bar_stat = "percent", width = 0.8, position = "dodge")
  )
  command <- chart_spec_command(bar)
  expect_match(command, "after_stat\\(count / sum\\(count\\) \\* 100\\)")
  expect_match(command, "width = 0.8")

  dot <- chart_gg_spec(
    "dot", options = list(binaxis = "y", stackdir = "up", dotsize = 1.5,
                          binwidth = 0.5)
  )
  command <- chart_spec_command(dot)
  expect_match(command, "binaxis = \"y\"")
  expect_match(command, "stackdir = \"up\"")
  expect_match(command, "dotsize = 1.5")
  expect_match(command, "binwidth = 0.5")

  strip <- chart_gg_spec(
    "strip", options = list(jitter_width = 0.3, jitter_height = 0.05,
                            shape = 17)
  )
  command <- chart_spec_command(strip)
  expect_match(command, "width = 0.3, height = 0.05")
  expect_match(command, "shape = 17")

  qq <- chart_gg_spec(
    "qq", options = list(distribution = "exp", line = FALSE)
  )
  command <- chart_spec_command(qq)
  expect_match(command, "stat_qq\\(distribution = stats::qexp\\)")
  expect_false(grepl("stat_qq_line", command, fixed = TRUE))

  means <- chart_gg_spec(
    "means", options = list(error_bars = "ci", connect = TRUE,
                            error_width = 0.3, point_size = 4)
  )
  command <- chart_spec_command(means)
  expect_match(command, "size = 4")
  expect_match(command, "mean_cl_normal")
  expect_match(command, "width = 0.3")
  expect_match(command, "geom = \"line\"")
})

test_that("the ggplot xyplot maps smooth and layout", {
  spec <- chart_gg_spec(
    "xyplot", mapping = list(x = "x", y = "y", group = "g2"),
    options = list(type = "b", smooth = TRUE, facet_ncol = 2)
  )
  command <- chart_spec_command(spec)
  expect_match(command, "ggplot2::geom_point")
  expect_match(command, "ggplot2::geom_line")
  expect_match(command, "ggplot2::geom_smooth\\(method = \"lm\"")
  expect_match(command, "ncol = 2")
})
