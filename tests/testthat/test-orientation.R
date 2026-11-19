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

# O4 — status bar hierarchy ---------------------------------------------------

test_that("the status bar has three groups and at most six facts", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:4, b = letters[1:4])

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    state$active_model <- "fit"
    state$undo_last_label <- "Rename column"
    session$setInputs(main_tabs = "data", menu_search = "",
                      data_mode = "view")
    session$flushReact()
    session$setInputs(data_selection_mode = "cells")
    session$flushReact()
    session$setInputs(data_filter_column = "a", data_filter_value = "2")
    session$elapse(500)
    session$flushReact()
    session$setInputs(data_cell_selection = list(
      row_ids = 2L, columns = "a", r1 = 2L, c1 = 1L, r2 = 2L, c2 = 1L
    ))
    session$flushReact()

    html <- htmltools::renderTags(output$statusbar)$html
    expect_match(html, "rcmdr-status-identity", fixed = TRUE)
    expect_match(html, "rcmdr-status-selection", fixed = TRUE)
    expect_match(html, "rcmdr-status-action", fixed = TRUE)

    # <= 6 visible facts: data, shape, filter, selection, last action.
    facts <- lengths(regmatches(html, gregexpr("rcmdr-status-item", html)))
    expect_lte(facts, 6L)

    # Nothing disappears: it moves to the view that owns it.
    expect_false(grepl("RcmdrShiny Studio", html, fixed = TRUE))
    expect_false(grepl("history step", html, fixed = TRUE))
    expect_false(grepl("[0-9]+ plot", html))
    expect_false(grepl("Model:", html, fixed = TRUE))

    # The live region wrapper is untouched.
    page <- as.character(app_ui())
    expect_match(page, 'aria-live="polite"', fixed = TRUE)
    expect_match(page, 'aria-atomic="false"', fixed = TRUE)
  })
})

test_that("the counts live in Console, History and Chart Studio", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:4, b = letters[1:4])

  shiny::testServer(app_server(env), {
    state$log <- c("summary(D)", "plot(D)")
    state$history <- list(list(id = "1"), list(id = "2"), list(id = "3"))
    state$plots <- list(list(id = "p1"), list(id = "p2"))
    session$setInputs(menu_search = "")
    session$flushReact()

    expect_match(htmltools::renderTags(output$console_count_ui)$html,
                 "2 command(s)", fixed = TRUE)
    expect_match(htmltools::renderTags(output$history_count_ui)$html,
                 "3 history step(s)", fixed = TRUE)
    expect_match(htmltools::renderTags(output$chart_gallery_count_ui)$html,
                 "2 plot(s)", fixed = TRUE)
  })
})

test_that("the compact status bar hides the shape, which stays in data info", {
  css <- app_asset_text("css", "10-shell.css")
  compact <- regmatches(
    css,
    regexpr("@media \\(max-width: 991\\.98px\\) \\{[^@]*rcmdr-status-optional[^@]*\\}",
            css, perl = TRUE)
  )
  expect_match(compact, ".rcmdr-status-optional { display: none; }",
               fixed = TRUE)
  expect_match(css, ".rcmdr-status-group + .rcmdr-status-group", fixed = TRUE)
  expect_match(css, ".rcmdr-view-count", fixed = TRUE)
})

# O5 — workspace slot headers -------------------------------------------------

test_that("a split names both slots and their views", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3, b = 1:3)

  shiny::testServer(app_server(env), {
    session$setInputs(main_tabs = "data", menu_search = "",
                      workspace_secondary_view = "help",
                      workspace_focus = "split")
    session$flushReact()

    primary <- htmltools::renderTags(output$workspace_primary)$html
    expect_match(primary, "rcmdr-slot-header-primary", fixed = TRUE)
    expect_match(primary, "Primary", fixed = TRUE)
    expect_match(primary, "Data Studio", fixed = TRUE)
    expect_match(primary, 'aria-label="Primary view: Data Studio"',
                 fixed = TRUE)
    # The slot stays the F6 target: role, tabindex and the same name.
    expect_match(primary, 'data-rcmdr-focus-region="primary"', fixed = TRUE)
    expect_match(primary, 'tabindex="-1"', fixed = TRUE)

    secondary <- htmltools::renderTags(output$workspace_secondary)$html
    expect_match(secondary, "rcmdr-slot-header-secondary", fixed = TRUE)
    expect_match(secondary, "Secondary", fixed = TRUE)
    expect_match(secondary, "Help centre", fixed = TRUE)
    expect_match(secondary, 'aria-label="Secondary view: Help centre"',
                 fixed = TRUE)
    expect_match(secondary, 'data-rcmdr-focus-region="secondary"',
                 fixed = TRUE)
  })
})

test_that("a single slot has no redundant header", {
  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    session$setInputs(main_tabs = "home", menu_search = "",
                      workspace_secondary_view = "")
    session$flushReact()
    html <- htmltools::renderTags(output$workspace_layout)$html
    expect_false(grepl("rcmdr-slot-header", html, fixed = TRUE))
    expect_match(html, 'aria-label="Primary view"', fixed = TRUE)
  })
})

test_that("the slot header uses the accent and keeps the view name when narrow", {
  css <- app_asset_text("css", "60-views.css")
  expect_match(css, ".rcmdr-slot-header-primary { border-left-color: var(--rcmdr-accent); }",
               fixed = TRUE)
  expect_match(css, ".rcmdr-slot-header-secondary", fixed = TRUE)
  compact <- regmatches(
    css,
    regexpr("@media \\(max-width: 991\\.98px\\) \\{[^@]*rcmdr-slot-role[^@]*\\}",
            css, perl = TRUE)
  )
  expect_match(compact, ".rcmdr-slot-role, .rcmdr-slot-sep { display: none; }",
               fixed = TRUE)
  expect_false(grepl(".rcmdr-slot-view { display: none", compact, fixed = TRUE))
})

# O6 — predictable return -----------------------------------------------------

test_that("Escape closes one layer and lets the inner one claim the key", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "closeAndReturn", fixed = TRUE)
  expect_match(js, "event.defaultPrevented", fixed = TRUE)
  expect_match(js, "document.querySelector('.modal.show')", fixed = TRUE)
  expect_match(js, "document.getElementById('modeless_close')",
               fixed = TRUE)
  # The close button and Escape share one path back to the trigger.
  expect_match(js, "window.setTimeout(function () { previous.focus(); }",
               fixed = TRUE)
})

test_that("Reset layout closes the modeless panel without touching the data", {
  skip_if_not_installed("shiny")
  env <- new.env(parent = globalenv())
  env$D <- data.frame(a = 1:3, b = 1:3)

  shiny::testServer(app_server(env), {
    active_dataset(state, "D")
    state$history <- list(list(id = "1"), list(id = "2"))
    state$log <- c("summary(D)")
    state$undo_last_label <- "Rename column"
    state$data_selection <- list(dataset = "D", rows = 1L,
                                 columns = "a", expression = "", cells = NULL)

    session$setInputs(main_tabs = "home", menu_search = "",
                      modeless_view = "help")
    session$flushReact()
    panel <- htmltools::renderTags(output$modeless_panel)$html
    expect_match(panel, "rcmdr-modeless-panel", fixed = TRUE)

    state$reset_layout()
    session$setInputs(modeless_view = "")
    session$flushReact()
    expect_false(grepl("rcmdr-modeless-panel",
                       htmltools::renderTags(output$modeless_panel)$html,
                       fixed = TRUE))

    # Layout only: data, undo and history are untouched.
    expect_equal(active_dataset(state), "D")
    expect_length(state$history, 2L)
    expect_equal(state$log, "summary(D)")
    expect_equal(state$undo_last_label, "Rename column")
  })
})
