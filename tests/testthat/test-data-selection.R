# Data Studio Rows / Cells selection and TSV copy ------------------------------

selection_test_frame <- function() {
  data_grid_frame(data.frame(
    a = c(1, 2, 3), b = c("x", "y", "z"),
    stringsAsFactors = FALSE
  ))
}

test_that("Rows and Cells choose different grid callbacks", {
  rows <- as.character(grid_selection_callback("rows"))
  cells <- as.character(grid_selection_callback("cells"))
  expect_match(rows, "rcmdrGridSelection(table, 'rows')", fixed = TRUE)
  expect_match(cells, "rcmdrGridSelection(table, 'cells')", fixed = TRUE)
})

test_that("a cell range becomes TSV in view order", {
  state <- AppState(new.env())
  assign("D", data.frame(a = 1:3, b = c("x", "y", "z")), envir = state$env)
  active_dataset(state, "D")
  frame <- data_grid_frame(state$env$D)

  set_data_selection(
    state, rows = c(2L, 1L), columns = c("b", "a"),
    cells = list(row_ids = c(2L, 1L), columns = c("b", "a"),
                 range = "R1C1:R2C2")
  )
  expect_equal(selection_tsv(state, frame), "2\ty\n1\tx")
  expect_equal(selection_nonempty(selection_subset_frame(state, frame)), 4L)
  expect_match(selection_status_text(state, frame), "R1C1:R2C2")
  expect_match(selection_status_text(state, frame), "2 row\\(s\\)")
  expect_match(selection_status_text(state, frame), "4 non-empty")
})

test_that("a row selection copies every visible column without the row id", {
  state <- AppState(new.env())
  assign("D", data.frame(a = 1:3, b = c("x", "y", "z")), envir = state$env)
  active_dataset(state, "D")
  frame <- data_grid_frame(state$env$D)

  set_data_selection(state, rows = c(1L, 3L))
  expect_equal(selection_tsv(state, frame), "1\tx\n3\tz")
  expect_false(grepl(".row_id", selection_tsv(state, frame), fixed = TRUE))
})

test_that("tabs and newlines in values do not break the TSV grid", {
  state <- AppState(new.env())
  assign("D", data.frame(a = c("x\ty", "line\nbreak")), envir = state$env)
  active_dataset(state, "D")
  frame <- data_grid_frame(state$env$D)
  set_data_selection(state, rows = c(1L, 2L))
  expect_equal(selection_tsv(state, frame), "x y\nline break")
})

test_that("Copy selection is enabled only when something is selected", {
  state <- AppState(new.env())
  assign("D", data.frame(a = 1:2), envir = state$env)
  active_dataset(state, "D")
  expect_equal(command_status(state, "copySelection"), "disabled")
  expect_equal(command_availability(state, "copySelection")$status, "disabled")

  set_data_selection(state, rows = 1L)
  expect_equal(command_status(state, "copySelection"), "enabled")
  expect_equal(command_availability(state, "copySelection")$status, "enabled")
})

test_that("the Data Studio server records a cell range", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3, b = c("x", "y", "z"),
                      stringsAsFactors = FALSE)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "data", menu_search = "",
                      data_mode = "view", data_inspector_column = "a")
    session$flushReact()
    session$setInputs(data_selection_mode = "cells")
    session$flushReact()
    session$setInputs(data_cell_selection = list(
      row_ids = c(1L, 2L), columns = c("a", "b"),
      r1 = 1L, c1 = 1L, r2 = 2L, c2 = 2L
    ))
    session$flushReact()

    selection <- state$data_selection
    expect_equal(selection$rows, c(1L, 2L))
    expect_equal(selection$columns, c("a", "b"))
    expect_equal(selection$cells$range, "R1C1:R2C2")
    expect_equal(selection_tsv(state, data_view_frame()), "1\tx\n2\ty")
    expect_match(htmltools::renderTags(output$data_selection_bar)$html,
                 "Copy selection", fixed = TRUE)
    expect_match(htmltools::renderTags(output$statusbar)$html,
                 "R1C1:R2C2", fixed = TRUE)

    session$setInputs(data_selection_mode = "rows")
    session$flushReact()
    expect_null(state$data_selection)
  })
})

test_that("the clipboard fallback and Ctrl+C are wired", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "rcmdr-copy", fixed = TRUE)
  expect_match(js, "copy_selection_shortcut", fixed = TRUE)
  expect_match(js, "navigator.clipboard", fixed = TRUE)
  expect_match(js, "rcmdr-cell-selected", fixed = TRUE)
})
