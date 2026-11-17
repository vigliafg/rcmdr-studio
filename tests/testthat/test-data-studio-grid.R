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
