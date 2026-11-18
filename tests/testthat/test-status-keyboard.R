# Status bar and keyboard navigation (Wave 18, S9) ---------------------------

test_that("the status bar names the data set, the model and the last action", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3, b = 1:3)
  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    state$active_model <- "fit"
    state$undo_last_label <- "Rename column"
    session$setInputs(menu_search = "")
    session$flushReact()

    html <- htmltools::renderTags(output$statusbar)$html
    expect_match(html, "Data: D", fixed = TRUE)
    expect_match(html, "3 x 2", fixed = TRUE)
    expect_match(html, "Model: fit", fixed = TRUE)
    expect_match(html, "Last action: Rename column", fixed = TRUE)
    expect_match(html, "RcmdrShiny Studio", fixed = TRUE)
  })
})

test_that("the status bar is a focus region with a visible focus token", {
  html <- as.character(app_ui())
  expect_match(html, 'id="rcmdr-statusbar"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-focus-region="status"', fixed = TRUE)
  expect_match(html, 'tabindex="-1"', fixed = TRUE)
  expect_match(html, 'aria-live="polite"', fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".rcmdr-focus-region:focus", fixed = TRUE)
  expect_match(css,
               "outline: var(--rcmdr-focus-width) solid var(--rcmdr-focus);",
               fixed = TRUE)
})

test_that("the workspace renders primary and secondary focus regions", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    session$setInputs(main_tabs = "home", menu_search = "",
                      workspace_secondary_view = "")
    session$flushReact()
    html <- htmltools::renderTags(output$workspace_layout)$html
    expect_match(html, 'data-rcmdr-focus-region="primary"', fixed = TRUE)
    expect_match(html, 'aria-label="Primary view"', fixed = TRUE)
    expect_match(html, 'tabindex="-1"', fixed = TRUE)

    session$setInputs(workspace_secondary_view = "help")
    session$flushReact()
    secondary <- htmltools::renderTags(output$workspace_secondary)$html
    expect_match(secondary, 'data-rcmdr-focus-region="secondary"', fixed = TRUE)
    expect_match(secondary, 'aria-label="Secondary view"', fixed = TRUE)
  })
})

test_that("the inner panels are focus regions with a name", {
  spec <- data_studio_ui()
  html <- htmltools::renderTags(spec)$html
  expect_match(html, 'id="data-inspector-panel"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-focus-region="panel"', fixed = TRUE)

  chart <- chart_builder_ui(show_preview = TRUE)
  html <- htmltools::renderTags(chart)$html
  expect_match(html, 'id="chart-preview-panel"', fixed = TRUE)
  expect_match(html, 'aria-label="Preview"', fixed = TRUE)
})

test_that("F6 cycles the focus regions and never steals it from a modal", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "event.key !== 'F6'", fixed = TRUE)
  expect_match(js, "event.shiftKey ? -1 : 1", fixed = TRUE)
  expect_match(js, "data-rcmdr-focus-region=\"primary\"", fixed = TRUE)
  expect_match(js, "data-rcmdr-focus-region=\"status\"", fixed = TRUE)
  expect_match(js, "'.modal.show'", fixed = TRUE)
})

test_that("selection and undo are announced through the live region", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "rcmdr-announce", fixed = TRUE)
  expect_match(js, "rcmdr-live-status", fixed = TRUE)
})

test_that("a modeless panel has a title and a return button", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    session$setInputs(main_tabs = "home", menu_search = "",
                      modeless_view = "help")
    session$flushReact()
    html <- htmltools::renderTags(output$modeless_panel)$html
    expect_match(html, 'id="modeless-title"', fixed = TRUE)
    expect_match(html, "Back to workspace", fixed = TRUE)
    expect_match(html, 'data-rcmdr-focus-region="modeless"', fixed = TRUE)
    expect_match(html, 'aria-labelledby="modeless-title"', fixed = TRUE)
  })
})
