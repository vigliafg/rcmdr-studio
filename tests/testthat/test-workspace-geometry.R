# Persistent workspace geometry (Wave 18, S8) --------------------------------

test_that("geometry has a version and safe defaults", {
  geometry <- geometry_default()
  expect_equal(geometry$version, geometry_version)
  expect_equal(geometry$last_view, "home")
  expect_true(geometry$sidebar)
  expect_length(geometry$dialogs, 0L)
  expect_length(geometry$widths, 0L)
})

test_that("a corrupt or older geometry falls back to the default", {
  expect_equal(geometry_normalize(NULL), geometry_default())
  expect_equal(geometry_normalize(list(version = 99L, last_view = "data")),
               geometry_default())
  expect_equal(geometry_normalize("not a list"), geometry_default())
  expect_equal(geometry_normalize(list(version = geometry_version,
                                       last_view = "nope"))$last_view,
               "home")
  expect_equal(geometry_normalize(list(version = geometry_version,
                                       last_view = "Data"))$last_view,
               "data")
})

test_that("geometry validates widths and dialog sizes", {
  geometry <- geometry_normalize(list(
    version = geometry_version,
    last_view = "charts",
    sidebar = FALSE,
    widths = list(D = c(a = 120, b = 3, .row_id = 80, c = "x")),
    dialogs = list(histogram = list(width = 720, height = 560),
                   broken = list(width = NA, height = NA))
  ))
  expect_equal(geometry$last_view, "charts")
  expect_false(geometry$sidebar)
  # Low values clamp to the 40 px floor, high ones to the 1200 px ceiling,
  # and the hidden row id is never stored.
  expect_equal(geometry$widths$D, c(a = 120, b = 40))
  expect_false(".row_id" %in% names(geometry$widths$D))
  expect_equal(geometry$dialogs$histogram$width, 720)
  expect_null(geometry$dialogs$broken)
})

test_that("geometry survives a preferences round trip", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state <- AppState(env = new.env())
  geometry_set_last_view(state, "data")
  geometry_set_sidebar(state, FALSE)
  dialog_size_store(state, "histogram", width = 640, height = 480)
  data_widths_store(state, "D", c("a", "b"), c(120, 90))
  preferences_save(state, path)

  restored <- AppState(env = new.env())
  expect_true(preferences_load(restored, path))
  expect_equal(geometry_last_view(restored), "data")
  expect_false(geometry_sidebar(restored))
  expect_equal(dialog_size(restored, "histogram")$width, 640)
  expect_equal(data_widths_saved(restored, "D"), c(a = 120, b = 90))
})

test_that("column widths are clamped and never stored for the row id", {
  state <- AppState(env = new.env())
  assign("D", data.frame(a = 1:3, b = 1:3), envir = state$env)
  active_dataset(state, "D")

  data_widths_store(state, "D", c("a", "b", ".row_id"),
                    c(10, 400, 80))
  widths <- data_widths_saved(state, "D")
  expect_equal(widths, c(a = 40, b = 400))
  expect_false(".row_id" %in% names(widths))
  data_widths_store(state, "D", c("a"), c(5000))
  expect_equal(data_widths_saved(state, "D"), c(a = 1200))
  expect_null(data_widths_saved(state, "other"))
})

test_that("width definitions target the visible columns only", {
  state <- AppState(env = new.env())
  assign("D", data.frame(a = 1:3, b = 1:3), envir = state$env)
  active_dataset(state, "D")
  grid <- data_grid_frame(state$env$D)
  expect_length(data_width_defs(state, grid), 0L)

  data_widths_store(state, "D", c("a", "b"), c(120, 90))
  defs <- data_width_defs(state, grid)
  expect_equal(length(defs), 2L)
  expect_equal(defs[[1L]]$targets, 0L)
  expect_equal(defs[[1L]]$width, "120px")
  expect_equal(defs[[2L]]$targets, 1L)
  expect_equal(defs[[2L]]$width, "90px")
})

test_that("View > Reset layout restores geometry but keeps the data", {
  state <- AppState(env = new.env())
  assign("D", data.frame(y = 1:5), envir = state$env)
  active_dataset(state, "D")
  run_command(state, "D$y <- D$y + 1", log = FALSE)
  history_before <- length(state$history)
  log_before <- length(state$log)
  expect_length(state$undo_stack, 1L)

  geometry_set_last_view(state, "charts")
  geometry_set_sidebar(state, FALSE)
  dialog_size_store(state, "histogram", width = 800)
  data_widths_store(state, "D", "y", 140)
  state$options$workspace_panels <- list(data = list(inspector = FALSE))
  state$options$workspace_secondary <- "console"
  layout_set(state, "workspace_split", 0.4)
  column_order_store(state, "D", c("y"), names(state$env$D))

  expect_true(direct_commands()[["resetLayout"]](state))
  expect_equal(geometry_saved(state), geometry_default())
  expect_length(state$options$layouts, 0L)
  expect_length(state$options$column_order, 0L)
  expect_length(state$options$workspace_panels, 0L)
  expect_null(state$options$workspace_secondary)
  # The data, the log and the undo stack are not layout.
  expect_equal(state$env$D$y, 2:6)
  expect_equal(length(state$history), history_before)
  expect_equal(length(state$log), log_before)
  expect_length(state$undo_stack, 1L)
})

test_that("the server starts on the saved view and remembers the next one", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    state$options$preferences_file <- tempfile(fileext = ".rds")
    state$options$geometry <- geometry_default()
    geometry_set_last_view(state, "data")
    language_revision(language_revision() + 1L)
    session$flushReact()
    html <- htmltools::renderTags(output$main_tabs_ui)$html
    expect_match(html, 'value="data"', fixed = TRUE)

    session$setInputs(main_tabs = "charts")
    session$flushReact()
    expect_equal(geometry_last_view(state), "charts")

    session$setInputs(sidebar_collapsed = TRUE)
    session$flushReact()
    expect_false(geometry_sidebar(state))
  })
})

test_that("Reset layout returns the workspace to a single Home view", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    state$options$preferences_file <- tempfile(fileext = ".rds")
    session$setInputs(main_tabs = "charts", menu_search = "",
                      workspace_secondary_view = "data")
    session$flushReact()
    geometry_set_last_view(state, "charts")

    state$reset_layout()
    session$flushReact()
    expect_equal(geometry_last_view(state), "home")
    expect_equal(state$options$workspace_secondary, NULL)
    expect_equal(state$options$workspace_focus, "split")
  })
})

test_that("the client resizes columns and remembers the sidebar", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "data_column_widths", fixed = TRUE)
  expect_match(js, "rcmdr-col-resizer", fixed = TRUE)
  expect_match(js, "rcmdr-col-resizing", fixed = TRUE)
  expect_match(js, "sidebar_collapsed", fixed = TRUE)
  expect_match(js, "rcmdr-sidebar", fixed = TRUE)
  css <- as.character(app_css())
  expect_match(css, ".rcmdr-col-resizer", fixed = TRUE)
})
