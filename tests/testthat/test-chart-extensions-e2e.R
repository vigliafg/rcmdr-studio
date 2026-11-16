# Browser flow for the ggplot2 ecosystem: ggstatsplot, hrbrthemes, patchwork,
# the Models view and the Quarto download.
#
#   R CMD INSTALL -l /tmp/rcmdr-lib .
#   R_LIBS=/tmp/rcmdr-lib NOT_CRAN=true RCMDRSHINY_E2E=1 \
#     Rscript -e 'library(RcmdrShiny); testthat::test_file("tests/testthat/test-chart-extensions-e2e.R")'
#
# The app runs in a separate R process, so it must be installed: testing with
# pkgload::load_all() alone would exercise the previously installed copy.

chart_ext_ready <- function() {
  skip_if_not_installed("shinytest2")
  skip_if_not_installed("chromote")
  skip_if(Sys.getenv("RCMDRSHINY_E2E") != "1",
          "set RCMDRSHINY_E2E=1 to run the browser test")
}

chart_ext_switch_tab <- function(app, label) {
  # Activating the tab through its Shiny value is reliable; the DOM click is a
  # fallback for a tabset that has not bound its input yet.
  try(app$set_inputs(main_tabs = label, wait_ = FALSE), silent = TRUE)
  Sys.sleep(1)
  if (isTRUE(app$get_js(sprintf(
    "(function(){var p=document.querySelector('.tab-pane.active'); return p !== null && p.innerText.indexOf('%s') >= 0;})()",
    label
  )))) return(invisible(NULL))
  app$run_js(sprintf(
    "(function(){document.querySelectorAll('.modal-backdrop').forEach(function(m){m.remove();}); document.body.classList.remove('modal-open'); var link = Array.from(document.querySelectorAll('.nav-link')).find(function(a){return a.textContent.trim() === '%s';}); if (link) link.click();})()",
    label
  ))
  Sys.sleep(1)
}

# The first-run tour opens a modal 400 ms after load and swallows clicks, so it
# is closed through its own button ("Don't show again") before the flow starts.
chart_ext_dismiss_tour <- function(app) {
  shown <- tryCatch({
    app$wait_for_js("document.getElementById('tour_dismiss') !== null",
                    timeout = 20000)
    TRUE
  }, error = function(e) FALSE)
  if (shown) {
    app$click("tour_dismiss")
    Sys.sleep(1)
  }
  app$run_js(
    "document.querySelectorAll('.modal, .modal-backdrop').forEach(function(m){ m.remove(); }); document.body.classList.remove('modal-open');"
  )
}


# The Charts pane is inserted once the WebSocket connects, so wait for its
# controls instead of the first paint.
chart_ext_wait_builder <- function(app) {
  # The whole studio is already in the DOM behind the Home tab; the data set
  # selector only renders once the Charts tab is the active one.
  chart_ext_switch_tab(app, "Charts")
  app$wait_for_js(
    "(function(){var p=document.querySelector('.tab-pane.active'); return p !== null && p.innerText.indexOf('Create a chart') >= 0 && document.getElementById('chart_dataset') !== null && document.getElementById('chart_gg_theme') !== null;})()",
    timeout = 60000
  )
}

chart_ext_open_app <- function(name) {
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    y = c(2, 4, 6, 8, 10, 12),
    x = c(1, 2, 3, 4, 5, 6),
    g = factor(c("a", "b", "a", "b", "a", "b"))
  )
  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = name,
    width = 1400,
    height = 1100,
    load_timeout = 90000
  )
  app$wait_for_js("document.querySelectorAll('.nav-link').length > 0",
                  timeout = 60000)
  chart_ext_dismiss_tour(app)
  chart_ext_wait_builder(app)
  app
}

# Shiny renders the selects with selectize, which keeps the choices in JS and
# leaves a single <option> in the hidden element.
chart_ext_choices <- function(app, input_id) {
  raw <- app$get_js(sprintf(
    "(function(){var el=document.getElementById('%s'); if (!el) return ''; var opts = el.selectize ? el.selectize.options : null; var keys = opts ? Object.keys(opts).map(function(k){return opts[k].value;}) : Array.from(el.options).map(function(o){return o.value;}); return keys.join('|');})()",
    input_id
  ))
  strsplit(raw, "|", fixed = TRUE)[[1L]]
}

chart_ext_apply <- function(app, wait = 4) {
  app$click("chart_apply")
  Sys.sleep(wait)
}

test_that("the statistical charts and the axis formats reach the browser", {
  chart_ext_ready()
  skip_if_not_installed("ggstatsplot")
  skip_if_not_installed("hrbrthemes")

  app <- chart_ext_open_app("chart-extensions-flow")
  on.exit(app$stop(), add = TRUE)

  # ggstatsplot types, compositions and the hrbrthemes themes are offered by
  # the builder.
  types <- chart_ext_choices(app, "chart_type")
  expect_true(all(c("stat_compare", "stat_scatter", "stat_coef", "compose") %in% types))
  themes <- chart_ext_choices(app, "chart_gg_theme")
  expect_true(all(c("theme_ipsum", "theme_ipsum_rc", "theme_ft_rc") %in% themes))

  app$set_inputs(chart_mode = "build", chart_type = "stat_compare",
                 chart_dataset = "Dataset", wait_ = FALSE)
  app$wait_for_js("document.getElementById('chart_map_y') !== null",
                  timeout = 30000)
  app$set_inputs(chart_map_x = "g", chart_map_y = "y", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelector('#chart_preview_image img') !== null",
    timeout = 90000
  )
  command <- app$get_text("#chart_command_text")
  expect_match(command, "ggstatsplot::ggbetweenstats", fixed = TRUE)
  expect_match(command, "results.subtitle = TRUE", fixed = TRUE)

  # Back to a plain ggplot2 chart: the axis formats become scales labels.
  app$set_inputs(chart_type = "histogram", wait_ = FALSE)
  app$wait_for_js("document.getElementById('chart_map_x') !== null",
                  timeout = 30000)
  app$set_inputs(chart_map_x = "y", chart_gg_y_format = "percent",
                 wait_ = FALSE)
  Sys.sleep(2)
  app$wait_for_js(
    "document.querySelector('#chart_preview_image img') !== null",
    timeout = 90000
  )
  command <- app$get_text("#chart_command_text")
  expect_match(command, "ggplot2::geom_histogram", fixed = TRUE)
  expect_match(command, "scales::percent", fixed = TRUE)
  expect_match(command, "ggplot2::theme_minimal", fixed = TRUE)

  chart_ext_apply(app)
  app$set_inputs(chart_mode = "gallery", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('#chart_gallery_grid .rcmdr-chart-card').length >= 1",
    timeout = 30000
  )
})

test_that("two charts are composed with patchwork in the browser", {
  chart_ext_ready()
  skip_if_not_installed("patchwork")

  app <- chart_ext_open_app("chart-compose-flow")
  on.exit(app$stop(), add = TRUE)

  app$set_inputs(chart_mode = "build", chart_type = "histogram",
                 chart_dataset = "Dataset", wait_ = FALSE)
  app$wait_for_js("document.getElementById('chart_map_x') !== null",
                  timeout = 30000)
  app$set_inputs(chart_map_x = "y", wait_ = FALSE)
  Sys.sleep(2)
  chart_ext_apply(app)

  app$set_inputs(chart_type = "boxplot", wait_ = FALSE)
  app$wait_for_js("document.getElementById('chart_map_group') !== null",
                  timeout = 30000)
  app$set_inputs(chart_map_x = "y", chart_map_group = "g", wait_ = FALSE)
  Sys.sleep(2)
  chart_ext_apply(app)

  app$set_inputs(chart_type = "compose", wait_ = FALSE)
  app$wait_for_js("document.getElementById('chart_compose_plots') !== null",
                  timeout = 30000)
  app$set_inputs(chart_compose_plots = c("1", "2"), wait_ = FALSE)
  Sys.sleep(4)
  app$wait_for_js(
    "document.querySelector('#chart_preview_image img') !== null",
    timeout = 90000
  )
  command <- app$get_text("#chart_command_text")
  expect_match(command, "patchwork::plot_layout(guides = 'collect')",
               fixed = TRUE)
  expect_match(command, "patchwork::plot_annotation(tag_levels = 'A')",
               fixed = TRUE)
  expect_match(command, "ggplot2::geom_histogram", fixed = TRUE)
  expect_match(command, "ggplot2::geom_boxplot", fixed = TRUE)

  chart_ext_apply(app)
  app$set_inputs(chart_mode = "gallery", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('#chart_gallery_grid .rcmdr-chart-card').length >= 3",
    timeout = 30000
  )
  expect_match(app$get_js("document.getElementById('chart_gallery_grid').innerText"),
               "Composition of 2 charts", fixed = TRUE)
})

test_that("the Models view lists both taxonomies", {
  chart_ext_ready()

  app <- chart_ext_open_app("chart-models-flow")
  on.exit(app$stop(), add = TRUE)

  app$set_inputs(chart_mode = "models", wait_ = FALSE)
  app$wait_for_js(
    "document.querySelectorAll('#chart_models_grid .rcmdr-chart-card').length >= 20",
    timeout = 30000
  )
  cards <- app$get_js("document.getElementById('chart_models_grid').innerText")
  # Grouped both by analysis family and by chart type.
  expect_match(cards, "Group comparison", fixed = TRUE)
  expect_match(cards, "Repeated measures", fixed = TRUE)
  expect_match(cards, "Distribution", fixed = TRUE)
})

test_that("the Quarto download produces a .qmd document", {
  chart_ext_ready()
  skip_if_not_installed("quarto")

  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(y = 1:6, g = factor(rep(c("a", "b"), 3)))
  app <- shinytest2::AppDriver$new(
    RcmdrShiny::app(env = env),
    name = "chart-quarto-flow",
    width = 1400,
    height = 1100,
    load_timeout = 90000
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_js("document.querySelectorAll('.nav-link').length > 0",
                  timeout = 60000)
  chart_ext_dismiss_tour(app)
  chart_ext_switch_tab(app, "Report")
  Sys.sleep(3)
  app$wait_for_js(
    "(function(){var b=document.getElementById('report_download_qmd'); return b !== null && b.getAttribute('href') !== null;})()",
    timeout = 60000
  )

  download <- app$get_download("report_download_qmd")
  expect_true(file.exists(download))
  text <- paste(readLines(download, warn = FALSE), collapse = "\n")
  expect_match(text, "^---", perl = TRUE)
  expect_match(text, "format: html", fixed = TRUE)
})
