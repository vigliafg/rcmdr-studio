# Orientation layer (Wave 19).

# O2 — visual grammar ---------------------------------------------------------

test_that("every state icon exists and is a small inline SVG", {
  names <- names(rcmdr_icon_paths())
  expect_true(all(c("file", "folder", "arrow", "funnel", "lock", "server",
                    "undo") %in% names))
  for (name in c("file", "folder", "arrow", "funnel", "lock", "server",
                 "undo")) {
    svg <- as.character(rcmdr_icon(name, 14))
    expect_match(svg, "rcmdr-icon", fixed = TRUE)
    expect_match(svg, 'aria-hidden="true"', fixed = TRUE)
    expect_match(svg, "viewBox", fixed = TRUE)
  }
})

test_that("a context chip always carries its text", {
  neutral <- htmltools::renderTags(
    context_chip("filter: a 2", icon = "funnel")
  )$html
  expect_match(neutral, "rcmdr-badge-neutral", fixed = TRUE)
  expect_match(neutral, "filter: a 2", fixed = TRUE)
  expect_match(neutral, "rcmdr-icon", fixed = TRUE)
  # The icon is decorative: the text is the accessible name.
  expect_match(neutral, 'aria-hidden="true"', fixed = TRUE)

  warning <- htmltools::renderTags(
    context_chip("editing disabled: threshold exceeded",
                 icon = "lock", tone = "warning")
  )$html
  expect_match(warning, "rcmdr-badge-warning", fixed = TRUE)
  expect_match(warning, "editing disabled: threshold exceeded", fixed = TRUE)

  accent <- htmltools::renderTags(
    context_chip("Data Studio", tone = "accent")
  )$html
  expect_match(accent, "rcmdr-badge-accent", fixed = TRUE)
  expect_false(grepl("rcmdr-icon", accent, fixed = TRUE))

  expect_error(context_chip("x", icon = "not-an-icon"))
  expect_error(context_chip("x", tone = "purple"))
})

test_that("the chip tones are token pairs, not literal colours", {
  css <- app_asset_text("css", "20-components.css")
  expect_match(css, ".rcmdr-badge-accent", fixed = TRUE)
  expect_match(css, "border-color: var(--rcmdr-accent);", fixed = TRUE)
  accent <- regmatches(
    css, regexpr("\\.rcmdr-badge-accent\\s*\\{[^}]*\\}", css, perl = TRUE)
  )
  expect_false(grepl("#", accent, fixed = TRUE))
  expect_false(grepl("rgb(", accent, fixed = TRUE))
})

# O3 — context line -----------------------------------------------------------

test_that("the context line names the place, the data and the filter", {
  state <- AppState(env = new.env())
  state$env$D <- data.frame(a = 1:4, b = letters[1:4])
  dataset_register(state, "D")
  active_dataset(state, "D")
  frame <- data_grid_frame(state$env$D)
  filtered <- frame[frame$a == 2, , drop = FALSE]

  html <- htmltools::renderTags(workspace_context_line(
    state, "data", filtered,
    filter = list(column = "a", value = "2"), selection_mode = "cells"
  ))$html

  expect_match(html, "rcmdr-context-line", fixed = TRUE)
  expect_match(html, "Studio \u00b7 Data Studio", fixed = TRUE)
  expect_match(html, "filter: a 2 \u00b7 1 of 4 rows", fixed = TRUE)
  expect_match(html, "Cells", fixed = TRUE)
  expect_match(html, "rcmdr-badge-accent", fixed = TRUE)
})

test_that("every workspace view has a place in the context line", {
  state <- AppState(env = new.env())
  labels <- main_tab_labels("studio")
  for (id in workspace_view_ids()) {
    html <- htmltools::renderTags(
      workspace_context_line(state, id)
    )$html
    expect_match(html, "Studio", fixed = TRUE, info = id)
    expect_match(html, labels[[id]] %||% id, fixed = TRUE, info = id)
  }
})

test_that("the context line is text, not a control", {
  state <- AppState(env = new.env())
  html <- htmltools::renderTags(workspace_context_line(state, "home"))$html
  # Nothing focusable: no button, input or link in the line itself.
  expect_false(grepl("<button", html, fixed = TRUE))
  expect_false(grepl("<input", html, fixed = TRUE))
  expect_false(grepl("<a ", html, fixed = TRUE))

  css <- app_asset_text("css", "10-shell.css")
  expect_match(css, ".rcmdr-context-line", fixed = TRUE)
  expect_match(css, ".rcmdr-context-place", fixed = TRUE)
  expect_match(css, "overflow-x: auto", fixed = TRUE)
})

test_that("the server renders the context line", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:4, b = letters[1:4])

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    session$setInputs(menu_search = "", data_mode = "view",
                      main_tabs = "data", data_selection_mode = "rows")
    session$flushReact()

    context <- htmltools::renderTags(output$workspace_context_ui)$html
    expect_match(context, "Studio \u00b7 Data Studio", fixed = TRUE)
    expect_match(context, "Rows", fixed = TRUE)
  })
})
