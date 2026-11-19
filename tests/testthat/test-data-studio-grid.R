test_that("the grid frame keeps stable row identifiers", {
  df <- data.frame(a = 1:4, b = letters[1:4])
  grid <- data_grid_frame(df)
  expect_equal(names(grid), c("a", "b", ".row_id"))
  expect_equal(grid$.row_id, 1:4)

  expect_equal(grid_rows_to_data(grid, c(1L, 3L)), c(1L, 3L))
  expect_equal(grid_rows_to_data(grid, integer()), integer())
  expect_equal(grid_rows_to_data(df, c(2L, 4L)), c(2L, 4L))
})

test_that("missingness is computed per variable", {
  env <- new.env()
  env$D <- data.frame(
    a = c(1, NA, 3, NA),
    b = c("x", "y", "z", "w"),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")

  table <- data_missingness(state)
  expect_equal(table$variable, c("a", "b"))
  expect_equal(table$missing, c(2L, 0L))
  expect_equal(table$percent, c(50, 0))
  expect_equal(nrow(data_missingness(state, "Missing")), 0L)
})

test_that("the Data Studio UI renders its toolbar and containers", {
  html <- htmltools::renderTags(data_studio_ui())$html
  expect_match(html, "rcmdr-toolbar")
  expect_match(html, "data_dataset_selector")
  expect_match(html, "data_grid")
  expect_match(html, "data_inspector")
  expect_match(html, "data_missingness")
  expect_match(html, "data_selection_bar")
  expect_match(html, "Import")
})

test_that("the inspector renders a profile without an active data set", {
  html <- htmltools::renderTags(data_inspector_ui(NULL))$html
  expect_match(html, "rcmdr-empty")
  expect_match(html, "No column selected")
})

test_that("the missingness bar reports each variable", {
  table <- data.frame(
    variable = c("a", "b"), missing = c(2L, 0L), percent = c(50, 0),
    stringsAsFactors = FALSE
  )
  html <- htmltools::renderTags(data_missingness_ui(table))$html
  expect_match(html, "Missing values")
  expect_match(html, "50")
  expect_match(html, "progress-bar")
})

test_that("the Data Studio server renders and runs row operations", {
  skip_if_not_installed("shiny")
  env <- new.env()
  env$D <- data.frame(a = 1:4, b = letters[1:4], stringsAsFactors = FALSE)

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", data_mode = "view",
                      data_inspector_column = "a")

    selector <- htmltools::renderTags(output$data_dataset_selector)$html
    expect_match(selector, "D \\(4 x 2\\)")

    grid <- htmltools::renderTags(output$data_grid)$html
    expect_match(grid, "data_studio_table")

    inspector <- htmltools::renderTags(output$data_inspector)$html
    expect_match(inspector, "integer - numeric")
    studio_ui <- htmltools::renderTags(data_studio_ui())$html
    expect_match(studio_ui, "Column actions")
    expect_match(studio_ui, "Create subset")

    session$setInputs(data_grid_selection = c(1L, 3L))
    session$flushReact()
    expect_equal(selection_summary(state), "2 row(s)")

    session$setInputs(data_duplicate_rows = 1)
    session$flushReact()
    expect_equal(nrow(state$env$D), 6L)
    expect_equal(nrow(checkpoint_list(state)), 1L)

    session$setInputs(data_add_row = 1)
    session$flushReact()
    expect_equal(nrow(state$env$D), 7L)
  })
})

test_that("the Data Studio view uses the shared components", {
  html <- htmltools::renderTags(data_studio_ui())$html
  expect_match(html, 'class="rcmdr-toolbar"', fixed = TRUE)
  expect_match(html, 'role="toolbar"', fixed = TRUE)
  expect_match(html, 'aria-label="[^"]+"')
  expect_match(html, "rcmdr-toolbar-fields", fixed = TRUE)
  expect_match(html, "rcmdr-toolbar-field-wide", fixed = TRUE)
  expect_match(html, "rcmdr-data-layout", fixed = TRUE)
  expect_match(html, "rcmdr-actions-tight", fixed = TRUE)
  # View/Edit is a two-choice parameter: it becomes the shared strip.
  expect_match(html, 'name="data_mode"', fixed = TRUE)
  expect_match(html, "rcmdr-segmented", fixed = TRUE)
  # No hand-written layout utility survives in the view.
  for (utility in c("d-flex", "gap-1", "gap-2", "row g-3", "col-lg-8",
                    "col-lg-4", "align-items-end")) {
    expect_false(grepl(utility, html, fixed = TRUE),
                 label = paste("Data Studio still writes", utility))
  }
})

test_that("the inspector uses the token grid and the note component", {
  html <- htmltools::renderTags(data_inspector_ui(list(
    variable = "y", class = "numeric", type = "numeric", label = "",
    units = "", n = 10L, missing = 0L, unique = 10L,
    stats = list(min = 1, max = 2, mean = 1.5, median = 1.5, sd = 0.5,
                 q1 = 1.25, q3 = 1.75)
  )))$html
  expect_match(html, 'class="rcmdr-dl"', fixed = TRUE)
  expect_match(html, "rcmdr-note", fixed = TRUE)
  expect_false(grepl("col-5", html, fixed = TRUE))
  expect_false(grepl("row small", html, fixed = TRUE))
})

test_that("the Data Studio grid exposes its table actions", {
  html <- htmltools::renderTags(data_studio_ui())$html
  expect_match(html, 'data-rcmdr-context-menu="data_grid_menu"', fixed = TRUE)
  expect_match(html, 'id="data_grid_menu"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-click="data_col_summary"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-click="data_delete_rows"', fixed = TRUE)
})

test_that("the column order buttons and the drop zone are in the UI", {
  html <- htmltools::renderTags(data_studio_ui())$html
  expect_match(html, 'id="data_column_left"', fixed = TRUE)
  expect_match(html, 'id="data_column_right"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-dropzone="data"', fixed = TRUE)
  expect_match(html, "Drag a column header to change the view order",
               fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-click="data_column_left"',
               fixed = TRUE)
})

test_that("the editor explains its read-only columns and the pending edit", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(
    y = 1:4,
    when = as.POSIXct("2026-11-18 10:00:00", tz = "UTC"),
    g = factor(c("a", "b", "a", "b"))
  )
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(data_mode = "edit")
    session$flushReact()
    html <- htmltools::renderTags(output$data_editor_note)$html
    expect_match(html, "Read-only in the editor: when", fixed = TRUE)
    expect_match(html, "Apply changes before leaving Edit", fixed = TRUE)
  })
})

# Large data (Wave 18, S10) ---------------------------------------------------

test_that("the grid plan separates the row budget from the cell budget", {
  state <- AppState(env = new.env())

  small <- data.frame(a = 1:10)
  plan <- data_grid_plan(state, small)
  expect_false(plan$server)
  expect_true(plan$editable)
  expect_equal(plan$output_id, "data_studio_table")

  # 6000 rows is above the row budget but still inside the cell budget.
  tall <- data.frame(a = seq_len(6000L))
  plan <- data_grid_plan(state, tall)
  expect_true(plan$server)
  expect_equal(plan$output_id, "data_studio_table_server")
  expect_true(plan$editable)

  # 3000 rows by 5 columns is 15000 cells: below the row budget, above the
  # editing threshold.
  wide <- as.data.frame(matrix(1, nrow = 3000L, ncol = 5L))
  plan <- data_grid_plan(state, wide)
  expect_false(plan$server)
  expect_false(plan$editable)
  expect_equal(plan$cells, 15000)
  expect_null(data_grid_plan(state, NULL))
})

test_that("the grid thresholds fall back to safe defaults", {
  state <- AppState(env = new.env())
  expect_equal(data_grid_server_threshold(state), 5000L)

  for (value in list(NA_integer_, -1L, integer(), "nope")) {
    state$options$dt_server_threshold <- value
    expect_equal(data_grid_server_threshold(state), 5000L)
  }
  state$options$dt_server_threshold <- 20000L
  expect_equal(data_grid_server_threshold(state), 20000L)

  state$options$edit_threshold <- NA_real_
  plan <- data_grid_plan(state, data.frame(a = 1:3))
  expect_false(plan$editable)
})

test_that("the grid notice names the limit that applies", {
  state <- AppState(env = new.env())
  expect_null(data_grid_notice(
    data_grid_plan(state, data.frame(a = 1:10)), "view"
  ))

  tall <- htmltools::renderTags(data_grid_notice(
    data_grid_plan(state, data.frame(a = seq_len(6000L))), "view"
  ))$html
  expect_match(tall, "rcmdr-note", fixed = TRUE)
  expect_match(tall, "Rows are paged on the server", fixed = TRUE)
  expect_false(grepl("Editing is disabled", tall, fixed = TRUE))

  wide <- as.data.frame(matrix(1, nrow = 3000L, ncol = 5L))
  view <- htmltools::renderTags(data_grid_notice(
    data_grid_plan(state, wide), "view"
  ))$html
  expect_match(view, "Editing is disabled above 10000 cells", fixed = TRUE)
  expect_match(view, "selection and copy still work", fixed = TRUE)

  edit <- htmltools::renderTags(data_grid_notice(
    data_grid_plan(state, wide), "edit"
  ))$html
  expect_match(edit, "alert alert-warning", fixed = TRUE)
})

test_that("a large data set renders the server table and says why", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  # 6000 rows by 3 columns: above both the row budget and the cell budget.
  env$Big <- data.frame(a = seq_len(6000L), b = seq_len(6000L),
                        c = seq_len(6000L))

  shiny::testServer(app_server(env), {
    active_dataset(state, "Big")
    session$setInputs(menu_search = "", data_mode = "view")
    session$flushReact()

    grid <- htmltools::renderTags(output$data_grid)$html
    expect_match(grid, "data_studio_table_server", fixed = TRUE)
    expect_match(grid, "Rows are paged on the server", fixed = TRUE)
    expect_match(grid, "Editing is disabled above 10000 cells", fixed = TRUE)

    info <- htmltools::renderTags(output$data_info)$html
    expect_match(info, "server-side paging", fixed = TRUE)
    expect_match(info, "editing disabled", fixed = TRUE)

    # Above the cell budget the editor is refused; the grid stays readable.
    session$setInputs(data_mode = "edit")
    session$flushReact()
    edit <- htmltools::renderTags(output$data_grid)$html
    expect_match(edit, "data_studio_table_server", fixed = TRUE)
    expect_match(edit, "alert alert-warning", fixed = TRUE)
    expect_false(grepl("rhandsontable", edit, fixed = TRUE))
  })
})

test_that("the editor is refused above the cell budget alone", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  # 3000 rows by 5 columns: client grid, but 15000 cells.
  env$Wide <- as.data.frame(matrix(seq_len(15000L), nrow = 3000L))

  shiny::testServer(app_server(env), {
    active_dataset(state, "Wide")
    session$setInputs(menu_search = "", data_mode = "edit")
    session$flushReact()
    grid <- htmltools::renderTags(output$data_grid)$html
    expect_match(grid, "data_studio_table", fixed = TRUE)
    expect_match(grid, "alert alert-warning", fixed = TRUE)
    expect_false(grepl("rhandsontable", grid, fixed = TRUE))
  })
})

test_that("small data keeps the client grid and no notice", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$Small <- data.frame(a = 1:4, b = letters[1:4])

  shiny::testServer(app_server(env), {
    active_dataset(state, "Small")
    session$setInputs(menu_search = "", data_mode = "view")
    session$flushReact()

    grid <- htmltools::renderTags(output$data_grid)$html
    expect_match(grid, "data_studio_table", fixed = TRUE)
    expect_false(grepl("data_studio_table_server", grid, fixed = TRUE))
    expect_false(grepl("Rows are paged", grid, fixed = TRUE))
  })
})

test_that("the grid callback carries the translated keyboard labels", {
  callback <- as.character(grid_selection_callback("rows", "D"))
  expect_match(callback, "rcmdrGridSelection(table, 'rows', 'D',", fixed = TRUE)
  expect_match(callback, "'Data grid'", fixed = TRUE)
  expect_match(callback, "'Resize column'", fixed = TRUE)
  # An apostrophe in a data set name must not break the JS string.
  callback <- as.character(grid_selection_callback("cells", "O'Brien"))
  expect_match(callback, "'O\\'Brien'", fixed = TRUE)
})

# Visible view (Wave 19, O1) --------------------------------------------------

test_that("the view shape follows the filter, not the data set", {
  state <- AppState(env = new.env())
  state$env$D <- data.frame(a = 1:4, b = letters[1:4])
  dataset_register(state, "D")
  active_dataset(state, "D")
  frame <- data_grid_frame(state$env$D)

  expect_equal(data_view_shape(state, frame), "4 x 2")
  expect_equal(data_view_shape(state, frame, long = TRUE),
               "4 rows x 2 columns, 8 cells")

  filtered <- frame[frame$a == 2, , drop = FALSE]
  filter <- list(column = "a", value = "2")
  expect_equal(data_filter_label("a", "2"), "a 2")
  expect_equal(data_view_shape(state, filtered, filter), "1 of 4 x 2")
  expect_equal(data_view_shape(state, filtered, filter, long = TRUE),
               "1 of 4 rows x 2 columns, 2 cells")

  # A filter that keeps every row is still a filter, but the count does not
  # repeat itself.
  expect_true(data_view_state(state, frame, list(column = "a", value = ""))$filtered
              == FALSE)
  same <- data_view_state(state, frame, list(column = "a", value = "1"))
  expect_true(same$filtered)
  expect_equal(data_view_shape(state, frame, list(column = "a", value = "1")),
               "4 x 2")

  expect_equal(data_filter_label("when", NULL,
                                 c("2026-01-01", "2026-01-31")),
               "when 2026-01-01..2026-01-31")
  expect_equal(data_filter_label("when", NULL, "2026-01-01"),
               "when 2026-01-01")
  expect_equal(data_filter_label("", "2"), "")
  expect_null(data_view_state(AppState(env = new.env()), NULL, NULL))
})

test_that("the status bar reports the filtered shape", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:4, b = letters[1:4])

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", data_mode = "view",
                      data_filter_column = "a", data_filter_value = "2")
    session$elapse(500)
    session$flushReact()

    info <- htmltools::renderTags(output$data_info)$html
    expect_match(info, "1 of 4 rows x 2 columns, 2 cells", fixed = TRUE)

    status <- htmltools::renderTags(output$statusbar)$html
    expect_match(status, "1 of 4 x 2", fixed = TRUE)
    expect_match(status, "filter: a 2", fixed = TRUE)
  })
})
