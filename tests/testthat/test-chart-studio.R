# Chart Studio UI and server -------------------------------------------------

test_that("the Chart Studio UI exposes the builder and gallery", {
  html <- htmltools::renderTags(chart_studio_ui())$html
  expect_match(html, "rcmdr-toolbar")
  expect_match(html, "chart_mode")
  expect_match(html, "chart_type")
  expect_match(html, "chart_dataset_ui")
  expect_match(html, "chart_mapping_ui")
  expect_match(html, "chart_options_ui")
  expect_match(html, "chart_preview_media")
  expect_match(html, "chart_preview_selection")
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
    expect_match(output$chart_command_text, "ggplot2::ggplot\\(D")

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

test_that("the Models view opens a model in the builder", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:6, x = 2 * (1:6), g = factor(rep(c("a", "b"), 3)))

  suppressWarnings(shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    session$setInputs(menu_search = "", chart_mode = "models",
                      chart_models_analysis = "all", chart_models_type = "all",
                      chart_models_query = "")
    session$flushReact()

    grid <- htmltools::renderTags(output$chart_models_grid)$html
    expect_match(grid, "chart_model_action")
    expect_match(grid, "Histogram")

    # MockShinySession records update* messages without applying them to
    # `input`, so the observer is checked for a clean run and the loaded
    # specification is verified through its pure helper.
    expect_error(
      {
        session$setInputs(chart_model_action = list(id = "box_by_group"))
        session$flushReact()
      },
      NA
    )
    spec <- chart_model_spec(chart_model("box_by_group"), "Dataset")
    expect_equal(spec$type, "boxplot")
    expect_equal(spec$theme$ggplot_theme, "bw")
  }))
})

test_that("the composition panel lists the gallery charts", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("patchwork")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:6, x = 2 * (1:6), g = factor(rep(c("a", "b"), 3)))

  suppressWarnings(shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    chart_apply(state, chart_spec("histogram", "Dataset", list(x = "y")))
    chart_apply(state, chart_spec("bar", "Dataset", list(x = "g")))

    session$setInputs(menu_search = "", chart_mode = "build",
                      chart_type = "compose", chart_dataset = "Dataset",
                      chart_compose_plots = c("1", "2"), chart_palette = "default",
                      chart_base_size = 12, chart_grid = TRUE,
                      chart_legend = "right", chart_background = "white",
                      chart_title = "", chart_xlab = "", chart_ylab = "",
                      chart_caption = "", chart_width = 800, chart_height = 600,
                      chart_gg_theme = "minimal", chart_gg_alpha = 0.7,
                      chart_gg_binwidth = 0, chart_gg_jitter = 0,
                      chart_gg_shape = 19, chart_gg_facet_ncol = 0,
                      chart_gg_facet_scales = "fixed", chart_gg_position = "identity",
                      chart_gg_smooth = "lm", chart_gg_se = FALSE,
                      chart_gg_flip = FALSE, chart_gg_subtitle = "",
                      chart_gg_tag = "", chart_gg_x_format = "auto",
                      chart_gg_y_format = "auto", chart_gg_polar = FALSE,
                      chart_gg_polar_theta = "x")
    session$flushReact()

    panel <- htmltools::renderTags(output$chart_compose_ui)$html
    expect_match(panel, "chart_compose_plots")
    command <- output$chart_command_text
    expect_match(command, "patchwork::plot_layout", fixed = TRUE)
  }))
})

test_that("the Chart Studio frame uses the shared components", {
  html <- htmltools::renderTags(chart_studio_ui())$html
  expect_match(html, 'class="rcmdr-toolbar"', fixed = TRUE)
  expect_match(html, "rcmdr-segmented", fixed = TRUE)
  expect_match(html, "rcmdr-chart-layout", fixed = TRUE)
  expect_match(html, "rcmdr-toolbar-fields", fixed = TRUE)
  expect_match(html, "rcmdr-actions", fixed = TRUE)
  expect_match(html, "rcmdr-note", fixed = TRUE)
  # Build/Models/Gallery are three short labels: one segmented control.
  expect_match(html, 'name="chart_mode"', fixed = TRUE)
  for (utility in c("d-flex", "row g-3", "row g-2", "col-xl-5",
                    "col-xl-7", "col-md-3", "col-md-4", "align-items-end")) {
    expect_false(grepl(utility, html, fixed = TRUE),
                 label = paste("Chart Studio still writes", utility))
  }
})

test_that("the gallery and model cards use the shared components", {
  table <- data.frame(
    index = 1L, id = "plot-0001", title = "A", type = "histogram",
    dataset = "D", time = "now", pinned = FALSE, code = "Hist(...)",
    url = "", stringsAsFactors = FALSE
  )
  html <- htmltools::renderTags(chart_gallery_ui_cards(table))$html
  expect_match(html, "rcmdr-note", fixed = TRUE)
  expect_match(html, 'class="rcmdr-actions rcmdr-actions-tight"', fixed = TRUE)
  expect_false(grepl("d-flex", html, fixed = TRUE))

  models <- chart_model_table()
  html <- htmltools::renderTags(chart_models_cards(models))$html
  expect_match(html, "rcmdr-note", fixed = TRUE)
  expect_match(html, "rcmdr-actions-tight", fixed = TRUE)
  expect_false(grepl("d-flex", html, fixed = TRUE))
})

test_that("the builder keeps its identity card and six settings panels", {
  html <- htmltools::renderTags(chart_builder_ui())$html

  expect_match(html, "rcmdr-chart-identity", fixed = TRUE)
  expect_match(html, 'id="chart_settings"', fixed = TRUE)
  expect_match(html, 'class="accordion-item"', fixed = TRUE)
  expect_equal(
    lengths(regmatches(html, gregexpr('class="accordion-item"', html))), 6L
  )
  for (panel in c("Options", "Style", "Axes", "Text", "Theme", "Output")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  # Only Options starts open: the identity card carries the required choices.
  expect_equal(
    lengths(regmatches(
      html, gregexpr('class="accordion-collapse collapse show"', html)
    )), 1L
  )

  # No static control was lost or duplicated in the move.
  ids <- c(
    "chart_type", "chart_palette", "chart_base_size", "chart_legend",
    "chart_background", "chart_grid", "chart_title", "chart_caption",
    "chart_xlab", "chart_ylab", "chart_gg_theme", "chart_gg_position",
    "chart_gg_alpha", "chart_gg_binwidth", "chart_gg_smooth",
    "chart_gg_jitter", "chart_gg_shape", "chart_gg_se", "chart_gg_flip",
    "chart_gg_facet_scales", "chart_gg_facet_ncol", "chart_gg_subtitle",
    "chart_gg_tag", "chart_gg_x_format", "chart_gg_y_format",
    "chart_gg_polar", "chart_gg_polar_theta", "chart_width", "chart_height"
  )
  for (id in ids) {
    hits <- lengths(regmatches(
      html, gregexpr(sprintf('id="%s"', id), html, fixed = TRUE)
    ))
    expect_equal(hits, 1L, label = id)
  }

  # The dynamic per-type options and the arbitrary help keep their slots.
  expect_match(html, "chart_options_ui", fixed = TRUE)

  # The eighteen ggplot2 fields are spread over four panels, once each.
  gg <- regmatches(html, gregexpr('id="chart_gg_[a-z_]+"', html))[[1]]
  expect_equal(length(gg), 17L)
  expect_equal(anyDuplicated(gg), 0L)
})

test_that("each semantic panel owns its fields and nothing else", {
  html <- htmltools::renderTags(chart_builder_ui())$html
  panel_fields <- function(value) {
    start <- regexpr(sprintf('data-value="%s"', value), html, fixed = TRUE)[[1]]
    rest <- substring(html, start)
    end <- regexpr('data-value="', substring(rest, 20), fixed = TRUE)[[1]]
    body <- if (end > 0) substr(rest, 1, end + 18) else rest
    # The Output panel is the last one: stop before the preview column.
    preview <- regexpr('rcmdr-chart-preview-column', body, fixed = TRUE)[[1]]
    if (preview > 0) body <- substr(body, 1, preview - 1)
    sort(regmatches(body, gregexpr('id="(chart_[a-z_]+|chart_gg_[a-z_]+)"',
                                   body))[[1]])
  }

  expect_setequal(
    panel_fields("Style"),
    paste0('id="chart_gg_', c("position", "alpha", "binwidth", "jitter",
                              "shape", "smooth", "se", "flip"), '"')
  )
  expect_setequal(
    panel_fields("Axes"),
    paste0('id="chart_gg_', c("x_format", "y_format", "facet_scales",
                              "facet_ncol", "polar", "polar_theta"), '"')
  )
  expect_setequal(
    panel_fields("Text"),
    paste0('id="', c("chart_title", "chart_caption", "chart_xlab",
                     "chart_ylab", "chart_base_size", "chart_gg_subtitle",
                     "chart_gg_tag"), '"')
  )
  expect_setequal(
    panel_fields("Theme"),
    paste0('id="', c("chart_gg_theme", "chart_palette", "chart_legend",
                     "chart_background", "chart_grid"), '"')
  )
  expect_setequal(
    panel_fields("Output"),
    paste0('id="', c("chart_width", "chart_height"), '"')
  )
})

test_that("the per-type options keep the panels that survive a type change", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:6, x = 2 * (1:6),
                            g = factor(rep(c("a", "b"), 3)))

  suppressWarnings(shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    session$setInputs(
      menu_search = "", chart_mode = "build", chart_type = "boxplot",
      chart_dataset = "Dataset", chart_map_x = "y", chart_map_group = "",
      chart_type_options = c("Box", "Layout")
    )
    session$flushReact()

    html <- htmltools::renderTags(output$chart_options_ui)$html
    expect_match(html, 'id="chart_type_options"', fixed = TRUE)
    expect_match(html, "rcmdr-accordion-nested", fixed = TRUE)
    # One level below the builder accordion, and still a heading.
    expect_equal(
      lengths(regmatches(html, gregexpr('aria-level="4"', html))), 2L
    )
    expect_equal(
      lengths(regmatches(html, gregexpr('class="accordion-item"', html))), 2L
    )
    # Both groups were open and both are still available on a boxplot.
    expect_equal(
      lengths(regmatches(html, gregexpr("collapse show", html))), 2L
    )

    # A dot plot shares only Layout: Box is gone, Layout stays open, and the
    # first group of the new type is not forced open on top of it.
    session$setInputs(chart_type_options = c("Box", "Layout"),
                      chart_type = "dot")
    session$flushReact()
    html <- htmltools::renderTags(output$chart_options_ui)$html
    expect_false(grepl('data-value="Box"', html, fixed = TRUE))
    expect_match(html, 'data-value="Layout"', fixed = TRUE)
    expect_equal(
      lengths(regmatches(html, gregexpr("collapse show", html))), 1L
    )
    for (id in c("chart_opt_bin", "chart_opt_binaxis", "chart_opt_stackdir",
                 "chart_opt_dotsize", "chart_opt_binwidth")) {
      expect_match(html, sprintf('id="%s"', id), fixed = TRUE)
    }
  }))
})

test_that("a type without metadata still renders one options panel", {
  info <- chart_type("histogram")
  html <- as.character(
    chart_options_accordion(info, chart_spec("histogram", "D", list()))
  )
  expect_equal(
    lengths(regmatches(html, gregexpr('class="accordion-item"', html))), 1L
  )
  expect_match(html, 'data-value="Options"', fixed = TRUE)
})

test_that("the bounded parameters are sliders and the colour is a picker", {
  html <- htmltools::renderTags(chart_builder_ui())$html
  for (id in c("chart_gg_alpha", "chart_gg_jitter", "chart_base_size")) {
    expect_match(html, sprintf('id="%s" class="sw-no-ui-slider"', id),
                 fixed = TRUE)
  }
  expect_match(html, 'id="chart_background" class="form-control sw-spectrum"',
               fixed = TRUE)
  # The boxplot notch width follows the same rule.
  box <- as.character(
    chart_type("boxplot")$controls(chart_spec("boxplot", "D", list()))
  )
  expect_match(box, 'id="chart_opt_notchwidth" class="sw-no-ui-slider"',
               fixed = TRUE)
})

test_that("Reset moves the sliders and keeps the default command", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:6, x = 2 * (1:6),
                            g = factor(rep(c("a", "b"), 3)))

  suppressWarnings(shiny::testServer(app_server(env), {
    active_dataset(state, "Dataset")
    session$setInputs(
      menu_search = "", chart_mode = "build", chart_type = "boxplot",
      chart_dataset = "Dataset", chart_map_x = "y", chart_map_group = "",
      chart_gg_alpha = 0.4, chart_gg_jitter = 0.3, chart_base_size = 20,
      chart_opt_notchwidth = 0.8, chart_background = "#101010"
    )
    session$flushReact()

    # Reset reaches a noUi handle through the wrapper message, and a colour
    # field through updateSpectrumInput: neither may throw.
    expect_error({
      session$setInputs(chart_reset = 1)
      session$flushReact()
    }, NA)

    # The value the server reads is still a number and a colour string.
    session$setInputs(chart_gg_alpha = 0.35, chart_background = "#ffffff")
    session$flushReact()
    command <- output$chart_command_text
    expect_match(command, "alpha = 0.35", fixed = TRUE)
    # Pure white is the default surface: no plot.background layer.
    expect_false(grepl("plot.background", command, fixed = TRUE))
  }))
})

test_that("dense chart parameters carry a tip without losing the help text", {
  html <- htmltools::renderTags(chart_builder_ui())$html
  expect_match(html, "rcmdr-help-tip-trigger", fixed = TRUE)
  expect_match(html, "bslib-tooltip", fixed = TRUE)
  expect_match(html, "Alpha sets how transparent", fixed = TRUE)
  expect_match(html, "Jitter spreads overlapping points", fixed = TRUE)
  expect_match(html, "Facet scales let each panel", fixed = TRUE)
  # The tip complements the permanent mapping help.
  expect_match(html, "The mapping fields change with the chart type",
               fixed = TRUE)
})

test_that("gallery cards carry their own context menu", {
  table <- data.frame(
    index = c(2L, 1L), id = c("plot-0002", "plot-0001"),
    title = c("B", "A"), type = c("scatter", "histogram"),
    dataset = c("D", "D"), time = c("now", "now"),
    pinned = c(TRUE, FALSE), code = c("scatterplot(...)", "Hist(...)"),
    url = c("", ""), stringsAsFactors = FALSE
  )
  html <- htmltools::renderTags(chart_gallery_ui_cards(table))$html
  expect_match(html, "data-rcmdr-context-menu=", fixed = TRUE)
  expect_match(html, "chart_card_menu_", fixed = TRUE)
  expect_match(html, 'role="menu"', fixed = TRUE)
  expect_match(html, "data-rcmdr-menu-input=\"chart_action\"", fixed = TRUE)
})
