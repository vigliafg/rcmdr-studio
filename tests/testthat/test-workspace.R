test_that("the workspace lists the stable Studio views", {
  expect_equal(
    workspace_view_ids(),
    c("home", "workflows", "data", "charts", "report", "script",
      "console", "environment", "help")
  )
  expect_equal(workspace_view_ui("nope"), home_pane_ui())
})

test_that("the switcher marks one view and keeps data-values", {
  html <- as.character(workspace_view_switcher("data"))
  expect_match(html, "rcmdr-view-switcher", fixed = TRUE)
  expect_match(html, 'role="tablist"', fixed = TRUE)
  expect_match(html, 'data-value="data"', fixed = TRUE)
  expect_match(html, 'aria-selected="true"', fixed = TRUE)
  expect_match(html, "rcmdrSetView(&#39;data&#39;)", fixed = TRUE)
})

test_that("the second slot renders another view without duplicating it", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:5, x = 1:5)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "data", menu_search = "",
                      workspace_secondary_view = "charts",
                      workspace_focus = "split")
    session$flushReact()
    layout <- htmltools::renderTags(output$workspace_layout)$html
    expect_match(layout, "rcmdr-workspace-split", fixed = TRUE)
    expect_match(layout, "workspace_primary", fixed = TRUE)
    expect_match(layout, "workspace_secondary", fixed = TRUE)

    primary <- htmltools::renderTags(output$workspace_primary)$html
    expect_match(primary, "data_grid", fixed = TRUE)
    secondary <- htmltools::renderTags(output$workspace_secondary)$html
    expect_match(secondary, "chart_mode", fixed = TRUE)
  })
})

test_that("the second view is persisted as a preference", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  state <- AppState(env = new.env())
  state$options$workspace_secondary <- "charts"
  preferences_save(state, path)
  restored <- AppState(env = new.env())
  expect_true(preferences_load(restored, path))
  expect_equal(restored$options$workspace_secondary, "charts")

  restored$options$workspace_secondary <- "not a view"
  preferences_save(restored, path)
  again <- AppState(env = new.env())
  preferences_load(again, path)
  expect_null(again$options$workspace_secondary)
})

test_that("a view visible in the second slot is ready", {
  input <- list(main_tabs = "data", workspace_secondary_view = "charts")
  expect_true(view_ready(input, "data"))
  expect_true(view_ready(input, "charts"))
  expect_false(view_ready(input, "report"))
  expect_true(view_ready(list(), "help"))
})

test_that("panel visibility is stored per view", {
  state <- AppState(env = new.env())
  expect_false(workspace_panel_hidden(state, "data", "inspector"))
  workspace_panel_set(state, "data", "inspector", FALSE)
  expect_true(workspace_panel_hidden(state, "data", "inspector"))
  expect_false(workspace_panel_hidden(state, "charts", "inspector"))
})

test_that("hiding the inspector removes it from the Data view", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:5, x = 1:5)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "data", menu_search = "",
                      workspace_show_inspector = FALSE)
    session$flushReact()
    html <- htmltools::renderTags(output$workspace_primary)$html
    expect_false(grepl("data_inspector", html, fixed = TRUE))
    expect_true(grepl("data_grid", html, fixed = TRUE))
  })
})

test_that("focus mode shows one side of the split", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(y = 1:5, x = 1:5)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(main_tabs = "data", menu_search = "",
                      workspace_secondary_view = "charts",
                      workspace_focus = "primary")
    session$flushReact()
    layout <- htmltools::renderTags(output$workspace_layout)$html
    expect_false(grepl("rcmdr-workspace-split", layout, fixed = TRUE))
    expect_match(layout, "data_grid", fixed = TRUE)

    session$setInputs(workspace_focus = "secondary")
    session$flushReact()
    layout <- htmltools::renderTags(output$workspace_layout)$html
    expect_match(layout, "chart_mode", fixed = TRUE)
    expect_false(grepl("data_grid", layout, fixed = TRUE))
  })
})
