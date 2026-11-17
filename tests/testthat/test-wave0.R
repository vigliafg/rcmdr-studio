# Wave 0 — Studio foundations ------------------------------------------------

test_that("feature flags and interface modes have stable defaults", {
  state <- AppState(env = new.env())
  expect_true(feature_enabled(state, "command_palette"))
  expect_true(feature_enabled(state, "history"))
  expect_true(feature_enabled(state, "dialog_preview"))
  expect_false(feature_enabled(state, "data_studio"))
  expect_equal(ui_mode(state), "studio")
  expect_equal(ui_theme(state), "system")

  set_feature(state, "data_studio", TRUE)
  expect_true(feature_enabled(state, "data_studio"))
  set_ui_mode(state, "classic")
  expect_equal(ui_mode(state), "classic")
  set_ui_theme(state, "dark")
  expect_equal(ui_theme(state), "dark")
  expect_error(set_feature(state, "unknown_feature", TRUE),
               "Unknown feature flag")
})

test_that("run_command records structured history without changing the log", {
  env <- new.env()
  state <- AppState(env = env)

  result <- run_command(state, "1 + 1", source = "script")
  expect_equal(result$status, "ok")
  expect_equal(state$log, "1 + 1")
  expect_length(state$history, 1L)
  entry <- state$history[[1L]]
  expect_equal(entry$source, "script")
  expect_equal(entry$command, "1 + 1")
  expect_equal(entry$status, "ok")
  expect_match(paste(entry$output, collapse = " "), "2")
  expect_true(is.numeric(entry$duration_ms))

  history <- history_as_data_frame(state)
  expect_equal(nrow(history), 1L)
  expect_equal(history$command, "1 + 1")
})

test_that("history can be searched, rerun and inserted into the script", {
  env <- new.env()
  state <- AppState(env = env)
  inserted <- NULL
  state$set_script <- function(value) inserted <<- value
  state$current_document_text <- function() ""

  run_command(state, "x <- 1", source = "console")
  entry <- history_recent(state, 1L)[[1L]]
  expect_equal(entry$source, "console")
  expect_identical(history_find(state, entry$id), entry)

  history_rerun(state, entry$id)
  expect_equal(length(state$log), 2L)
  expect_equal(state$history[[1L]]$source, "history")

  expect_true(history_insert_script(state, entry$id))
  expect_equal(inserted, "x <- 1")

  history_clear(state)
  expect_length(state$history, 0L)
  expect_null(history_find(state, entry$id))
})

test_that("previews are isolated from the log, output and plots", {
  env <- new.env()
  env$Dataset <- data.frame(x = 1:5, y = 2 * (1:5))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")

  output_before <- state$output
  plots_before <- length(state$plots)
  log_before <- length(state$log)

  preview <- preview_plot(state, "plot(Dataset$x, Dataset$y)")
  expect_equal(preview$type, "image")
  expect_true(file.exists(preview$file))
  expect_null(preview$error)
  expect_equal(state$output, output_before)
  expect_equal(length(state$plots), plots_before)
  expect_equal(length(state$log), log_before)

  markdown <- preview_markdown("# Title")
  expect_true(grepl("Title", markdown))
  preview_cleanup()
  expect_false(file.exists(preview$file))
})

test_that("preview_state_clone does not propagate state or session changes", {
  env <- new.env()
  state <- AppState(env = env)
  state$session <- "not-a-session"
  state$show_tab <- function(label) stop("should not be called")

  clone <- preview_state_clone(state)
  clone$options$digits <- 3L
  clone$log <- c(clone$log, "clone")
  expect_equal(state$options$digits, 7L)
  expect_length(state$log, 0L)
  expect_null(clone$session)
  expect_null(clone$show_tab)
  clone$notify()
})

test_that("the command palette indexes menus, help, data and history", {
  env <- new.env()
  env$Dataset <- data.frame(x = 1:5, y = 2 * (1:5))
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  run_command(state, "summary(Dataset)", source = "console")

  index <- palette_index(state)
  expect_true(nrow(index) > 100L)
  expect_true(any(index$type == "menu"))
  expect_true(any(index$type == "help"))
  expect_true(any(index$type == "dataset"))
  expect_true(any(index$type == "variable"))
  expect_true(any(index$type == "history"))

  results <- palette_search("numerical", index)
  expect_true(nrow(results) > 0L)
  expect_true(any(grepl("Numerical", results$label, ignore.case = TRUE)))

  empty <- palette_search("", index)
  expect_lte(nrow(empty), 20L)
})

test_that("UI components render stable markup", {
  html <- htmltools::renderTags(htmltools::tagList(
    status_pill("OK", "ok"),
    empty_state("Empty", "Nothing here"),
    metric_card("Rows", 10, "Data rows"),
    section_card("Section", "Body"),
    code_preview("1 + 1"),
    split_view("left", "right"),
    studio_toolbar("toolbar"),
    studio_breadcrumb(c("Statistics", "Summaries"))
  ))$html
  expect_match(html, "rcmdr-status-pill")
  expect_match(html, "rcmdr-empty")
  expect_match(html, "rcmdr-metric")
  expect_match(html, "rcmdr-code-preview")
  expect_match(html, "rcmdr-split")
  expect_match(html, "rcmdr-toolbar")
  expect_match(html, "rcmdr-breadcrumb")
})

test_that("the app server exposes Studio tabs and history output", {
  skip_if_not_installed("shiny")
  env <- new.env()
  env$Dataset <- data.frame(y = 1:5, x = 1:5)

  shiny::testServer(app_server(env), {
    session$setInputs(menu_search = "")
    tabs <- htmltools::renderTags(output$main_tabs_ui)$html
    expect_match(tabs, "Home")
    expect_match(tabs, "Chart Studio")
    expect_match(tabs, "Console")

    toggle <- htmltools::renderTags(output$ui_mode_toggle_ui)$html
    expect_match(toggle, "Classic")

    run_command(state, "summary(Dataset)", source = "dialog")
    session$flushReact()
    cards <- htmltools::renderTags(output$history_cards)$html
    expect_match(cards, "summary\\(Dataset\\)")
    expect_match(cards, "Rerun")

    session$setInputs(palette_query = "numerical")
    palette <- htmltools::renderTags(output$palette_results)$html
    expect_match(palette, "Numerical")

    session$setInputs(ui_mode_toggle = 1)
    expect_equal(ui_mode(state), "classic")
  })
})

test_that("history source choices use stable codes", {
  labels <- history_source_labels()
  expect_equal(unname(labels),
               c("all", "dialog", "script", "console", "menu", "data",
                 "chart", "report", "environment", "model", "history",
                 "checkpoint", "help"))
  expect_true(all(nzchar(names(labels))))
})

test_that("console detects interactive commands", {
  expect_true(console_is_interactive("readline('name? ')"))
  expect_true(console_is_interactive("menu(c('a', 'b'))"))
  expect_false(console_is_interactive("summary(Dataset)"))
})

test_that("dialog specs accept preview and preset metadata", {
  spec <- get_dialog_spec("numericalSummaries")
  expect_true(isTRUE(spec$preview))
  expect_true(isTRUE(spec$presets))
  expect_true(is.null(spec$category) || is.character(spec$category))

  options_spec <- get_dialog_spec("Options")
  expect_false(isTRUE(options_spec$preview))
})
