# Chart Studio UI and server -------------------------------------------------

test_that("the Chart Studio UI exposes the builder and gallery", {
  html <- htmltools::renderTags(chart_studio_ui())$html
  expect_match(html, "rcmdr-chart-toolbar")
  expect_match(html, "chart_mode")
  expect_match(html, "chart_type")
  expect_match(html, "chart_dataset_ui")
  expect_match(html, "chart_mapping_ui")
  expect_match(html, "chart_options_ui")
  expect_match(html, "chart_preview_image")
  expect_match(html, "chart_apply")
  expect_match(html, "chart_advanced")
  expect_match(html, "chart_gallery_query")
  expect_match(html, "chart_download_png")
})

test_that("the gallery cards show metadata and actions", {
  table <- data.frame(
    index = c(2L, 1L), id = c("plot-0002", "plot-0001"),
    title = c("B", "A"), type = c("scatter", "histogram"),
    dataset = c("D", "D"), time = c("now", "now"),
    pinned = c(TRUE, FALSE), code = c("scatterplot(...)", "Hist(...)"),
    url = c("", ""), stringsAsFactors = FALSE
  )
  html <- htmltools::renderTags(chart_gallery_ui_cards(table))$html
  expect_match(html, "rcmdr-chart-grid")
  expect_match(html, "rcmdr-chart-card pinned")
  expect_match(html, "Detail")
  expect_match(html, "Reopen")
  expect_match(html, "Copy code")
})

test_that("the gallery empty state is explicit", {
  html <- htmltools::renderTags(chart_gallery_ui_cards(plot_list(
    chart_test_state()
  )))$html
  expect_match(html, "No charts yet")
})

test_that("the Chart Studio server renders and applies a chart", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    y = 1:6, x = 2 * (1:6), g = factor(rep(c("a", "b"), 3))
  )

  shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    session$setInputs(
      menu_search = "", chart_mode = "build", chart_type = "histogram",
      chart_dataset = "Dataset", chart_map_x = "y", chart_map_group = "",
      chart_opt_scale = "frequency", chart_opt_breaks = "Sturges",
      chart_opt_bins = 30, chart_engine = "base",
      chart_palette = "default", chart_base_size = 12, chart_grid = TRUE,
      chart_legend = "right", chart_background = "white",
      chart_title = "", chart_xlab = "", chart_ylab = "", chart_caption = "",
      chart_width = 800, chart_height = 600
    )
    session$flushReact()

    dataset <- htmltools::renderTags(output$chart_dataset_ui)$html
    expect_match(dataset, "Dataset")
    mapping <- htmltools::renderTags(output$chart_mapping_ui)$html
    expect_match(mapping, "chart_map_x")
    options <- htmltools::renderTags(output$chart_options_ui)$html
    expect_match(options, "chart_opt_scale")
    expect_match(output$chart_command_text, "Hist\\(y")

    session$setInputs(chart_apply = 1)
    session$flushReact()
    expect_equal(length(state$plots), 1L)
    expect_equal(state$plots[[1L]]$spec$type, "histogram")

    gallery <- htmltools::renderTags(output$chart_gallery_grid)$html
    expect_match(gallery, "Histogram of y")
    detail <- htmltools::renderTags(output$chart_detail)$html
    expect_match(detail, "Command")
    expect_match(detail, "Specification")
  })
})

test_that("the Advanced action opens the matching dialog with memory", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:5, x = 1:5, g = factor(rep(c("a", "b"), 3)[1:5]))

  suppressWarnings(shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    session$setInputs(
      menu_search = "", chart_mode = "build", chart_type = "scatter",
      chart_dataset = "Dataset", chart_map_x = "x", chart_map_y = "y",
      chart_map_group = "", chart_opt_smooth = FALSE,
      chart_opt_boxplots = FALSE, chart_opt_log = "",
      chart_engine = "base", chart_palette = "default",
      chart_base_size = 12, chart_grid = TRUE, chart_legend = "right",
      chart_background = "white", chart_title = "", chart_xlab = "",
      chart_ylab = "", chart_caption = "", chart_width = 800,
      chart_height = 600
    )
    session$flushReact()
    suppressWarnings(session$setInputs(chart_advanced = 1))
    suppressWarnings(session$flushReact())
    expect_equal(state$current_dialog, "scatterPlot")
    expect_equal(get_dialog_memory(state, "scatterPlot")$x, "x")
    expect_equal(get_dialog_memory(state, "scatterPlot")$y, "y")
  }))
})
