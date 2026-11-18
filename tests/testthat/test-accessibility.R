# P7.21: accessibility smoke checks for the Studio shell.

test_that("the shell has the landmarks and the skip link", {
  html <- as.character(app_ui())
  expect_match(html, "Skip to main content")
  expect_match(html, "visually-hidden-focusable")
  expect_match(html, "href=\"#main-content\"")
  expect_match(html, "role=\"main\"")
  expect_match(as.character(app_topbar_ui()), "role=\"banner\"")
  expect_match(html, "aria-live=\"polite\"")
  expect_match(html, "id=\"main-content\"")
})

test_that("the menubar has menu semantics", {
  html <- as.character(menubar_ui(menu_tree()))
  expect_match(html, "role=\"menubar\"")
  expect_match(html, "aria-label")
  expect_match(html, "role=\"menuitem\"")
  expect_match(html, "aria-haspopup=\"true\"")
  expect_match(html, "<summary")
})

test_that("focus is visible and motion respects user preferences", {
  css <- as.character(app_css())
  expect_match(css, ":focus-visible")
  expect_match(css, "outline")
  expect_match(css, "prefers-reduced-motion")
})

test_that("inline validation is announced", {
  html <- as.character(dialog_validation_ui(list(
    numericalSummaries_x = "Pick a variable"
  )))
  expect_match(html, "role=\"alert\"")
  expect_match(html, "aria-live=\"assertive\"")
  expect_match(html, "Pick a variable")
})

test_that("the command palette has a labelled search field", {
  html <- as.character(palette_modal())
  expect_match(html, "for=\"palette_query\"")
  expect_match(html, "visually-hidden")
  expect_match(html, "Command palette")
  # The dialog itself is named by the header, and the header is the shared one.
  expect_match(html, 'aria-labelledby="rcmdr-modal-title"', fixed = TRUE)
  expect_match(html, 'id="rcmdr-modal-title">Command palette</h4>',
               fixed = TRUE)
  expect_match(html, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(html, "rcmdr-palette-filters", fixed = TRUE)
})

test_that("the status bar is a live region", {
  expect_match(as.character(app_js()), "rcmdr-tab", fixed = TRUE)
  html <- as.character(app_ui())
  expect_match(html, "role=\"status\"")
  expect_match(html, "rcmdr-statusbar")
})

test_that("dialogs can be moved by their header", {
  js <- as.character(app_js())
  expect_match(js, "pointerdown", fixed = TRUE)
  expect_match(js, "data-rcmdr-x", fixed = TRUE)
  expect_match(js, "rcmdr-dragging", fixed = TRUE)
  # Dragging is a pointer enhancement: the close button and the inputs inside
  # the header must keep working.
  expect_match(js, "button, a, input, select, textarea, label", fixed = TRUE)
  css <- as.character(app_css())
  expect_match(css, ".modal-header { cursor: grab", fixed = TRUE)
  expect_match(css, "body.rcmdr-dragging", fixed = TRUE)
})

test_that("focus is one token ring and motion can be reduced", {
  css <- as.character(app_css())
  expect_match(css, "--rcmdr-focus-width: 2px", fixed = TRUE)
  focus <- regmatches(css, regexpr(":focus-visible \\{[^}]*\\}", css,
                                   perl = TRUE))
  expect_length(focus, 1L)
  expect_match(focus, "outline: var(--rcmdr-focus-width) solid var(--rcmdr-focus)",
               fixed = TRUE)

  media <- regmatches(
    css,
    regexpr("@media \\(prefers-reduced-motion: reduce\\) \\{[^@]*", css,
            perl = TRUE)
  )
  expect_length(media, 1L)
  expect_match(media, "animation-duration: .01ms !important", fixed = TRUE)
  expect_match(media, "transition-duration: .01ms !important", fixed = TRUE)
  expect_match(media, "scroll-behavior: auto !important", fixed = TRUE)
})

test_that("every multi-column view collapses to one column", {
  css <- as.character(app_css())
  views <- c(
    "rcmdr-shell-body", "rcmdr-data-layout", "rcmdr-chart-layout",
    "rcmdr-script-workspace", "rcmdr-help-layout", "rcmdr-report-workspace"
  )
  for (view in views) {
    expect_match(
      css, sprintf("\\.%s \\{[^}]*display: grid", view),
      perl = TRUE, label = sprintf("%s is a grid", view)
    )
    expect_match(
      css,
      sprintf("\\.%s \\{ grid-template-columns: minmax\\(0, 1fr\\); \\}", view),
      perl = TRUE, label = sprintf("%s collapses to one column", view)
    )
  }
})

test_that("the palette is driven from the keyboard", {
  js <- as.character(app_js())
  expect_match(js, "ArrowDown", fixed = TRUE)
  expect_match(js, "ArrowUp", fixed = TRUE)
  expect_match(js, "Enter", fixed = TRUE)
  # Esc is Bootstrap's modal contract, so the dialog must keep it enabled.
  modal <- as.character(palette_modal())
  expect_false(grepl('data-bs-keyboard="false"', modal, fixed = TRUE))
})

test_that("the settings accordion exposes heading and state semantics", {
  html <- as.character(settings_accordion(
    id = "a11y_settings", open = "One",
    settings_panel("One", htmltools::tags$input(id = "one")),
    settings_panel("Two", htmltools::tags$input(id = "two"))
  ))
  # The header is a heading, so the panels appear in the document outline.
  expect_match(html, 'role="heading"', fixed = TRUE)
  expect_match(html, 'aria-level="3"', fixed = TRUE)
  # The button keeps aria-expanded in sync with the panel state.
  expect_match(html, 'aria-expanded="true"', fixed = TRUE)
  expect_match(html, 'aria-expanded="false"', fixed = TRUE)
  expect_match(html, 'aria-controls="bslib-accordion-panel-', fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".accordion .accordion-button:focus-visible",
               fixed = TRUE)
  expect_match(css, ".rcmdr-accordion .accordion-button:hover", fixed = TRUE)
})

test_that("a nested accordion keeps its own heading depth", {
  html <- as.character(settings_accordion(
    level = 4L, open = "Inner",
    settings_panel("Inner", htmltools::tags$input(id = "inner"))
  ))
  expect_match(html, 'aria-level="4"', fixed = TRUE)
  expect_equal(
    lengths(regmatches(html, gregexpr('role="heading"', html))), 1L
  )
  # The icon is decorative: the title carries the name.
  html <- as.character(settings_accordion(
    settings_panel("Theme", htmltools::tags$input(id = "t"), icon = "sliders")
  ))
  expect_match(html, 'aria-hidden="true"', fixed = TRUE)
})

test_that("accordion headers move with the arrow keys inside their group", {
  js <- as.character(app_js())
  # Up/Down move between headers; Home/End jump to the edges.
  expect_match(js, "target.closest('.accordion-button')", fixed = TRUE)
  expect_match(js, "accordion.classList.contains('rcmdr-accordion')",
               fixed = TRUE)
  # A nested accordion only navigates its own headers.
  expect_match(js, "el.closest('.accordion') === accordion", fixed = TRUE)
  for (key in c("ArrowDown", "ArrowUp", "Home", "End")) {
    expect_match(js, sprintf("event.key === '%s'", key), fixed = TRUE,
                 label = key)
  }
  # Only headers with a box take focus.
  expect_match(js, "el.getClientRects().length > 0", fixed = TRUE)
  # Esc is captured by the tooltip and the context menus only; the accordion
  # handler above never claims it.
  expect_match(js, "rcmdrMenuClose(true)", fixed = TRUE)
})

test_that("the searchable picker is named by its visible label", {
  html <- as.character(picker_input("pick", "Pick a variable", c(a = "A")))
  expect_match(html, 'id="pick-label"', fixed = TRUE)
  expect_match(html, '"ariaLabelledby":"pick-label"', fixed = TRUE)
})

test_that("the external widgets get a role, a name and the button keys", {
  js <- as.character(app_js())
  expect_match(js, '.vscomp-ele-wrapper[role="combobox"]', fixed = TRUE)
  expect_match(js, "setAttribute('role', 'slider')", fixed = TRUE)
  expect_match(js, "aria-orientation", fixed = TRUE)
  expect_match(js, "setAttribute('tabindex', '0')", fixed = TRUE)
  expect_match(js, "event.key !== ' '", fixed = TRUE)
  expect_match(js, "replacer.click()", fixed = TRUE)
})

test_that("validation never focuses a field with no box", {
  js <- as.character(app_js())
  expect_match(js, "function rcmdrFocusFirst(candidates)", fixed = TRUE)
  expect_match(js, "el.getClientRects().length > 0", fixed = TRUE)
  # The summary link and the field-error payload share the same guard.
  expect_match(js, "rcmdrFocusFirst([el])", fixed = TRUE)
  expect_match(js, "rcmdrFocusFirst(candidates)", fixed = TRUE)
})

test_that("a parameter tip opens on focus and closes with Esc", {
  js <- as.character(app_js())
  expect_match(js, "rcmdr-help-tip-trigger", fixed = TRUE)
  expect_match(js, "aria-describedby", fixed = TRUE)
  expect_match(js, "Tooltip.getInstance(trigger)", fixed = TRUE)
  # The capture listener stops the modal from closing with the tip.
  expect_match(js, "}, true);", fixed = TRUE)
  expect_match(js, "event.stopPropagation()", fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".rcmdr-help-tip-trigger:focus-visible", fixed = TRUE)
  expect_match(css, "--bs-tooltip-bg: var(--rcmdr-surface);", fixed = TRUE)
  expect_match(css, "--bs-tooltip-color: var(--rcmdr-text);", fixed = TRUE)
})

test_that("busy states are announced and notifications are capped", {
  html <- as.character(app_ui())
  expect_match(html, 'id="rcmdr-live-status"', fixed = TRUE)
  expect_match(html, 'aria-live="polite"', fixed = TRUE)
  expect_match(html, 'aria-atomic="true"', fixed = TRUE)

  js <- as.character(app_js())
  expect_match(js, "rcmdr-busy", fixed = TRUE)
  expect_match(js, "setAttribute('aria-busy', 'true')", fixed = TRUE)
  expect_match(js, "rcmdrLimitNotifications", fixed = TRUE)
  expect_match(js, "notes.length - 3", fixed = TRUE)
  expect_match(js, "shiny-notification-panel", fixed = TRUE)

  app <- readLines(test_path("..", "..", "R", "app.R"))
  expect_true(any(grepl("set_busy(TRUE, tr(\"Applying the command...\"))",
                        app, fixed = TRUE)))
  expect_true(any(grepl("set_busy(TRUE, tr(\"Running the command...\"))",
                        app, fixed = TRUE)))
  expect_true(any(grepl("set_busy(TRUE, tr(\"Running the script...\"))",
                        app, fixed = TRUE)))

  css <- as.character(app_css())
  expect_match(css, ".shiny-notification {", fixed = TRUE)
  expect_match(css, ".shiny-notification-error {", fixed = TRUE)
})

test_that("the split separator is a keyboard window splitter", {
  js <- as.character(app_js())
  expect_match(js, "rcmdr-splitter-divider", fixed = TRUE)
  expect_match(js, "event.key === 'ArrowLeft'", fixed = TRUE)
  expect_match(js, "event.key === 'ArrowRight'", fixed = TRUE)
  expect_match(js, "event.key === 'Home'", fixed = TRUE)
  expect_match(js, "event.key === 'End'", fixed = TRUE)
  expect_match(js, "splitReset(divider, true)", fixed = TRUE)
  expect_match(js, "event.shiftKey ? 8 : 2", fixed = TRUE)
  expect_match(js, "setPointerCapture", fixed = TRUE)
  expect_match(js, "aria-valuetext", fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".rcmdr-splitter {", fixed = TRUE)
  expect_match(css, ".rcmdr-splitter-divider {", fixed = TRUE)
  expect_match(css, "cursor: col-resize", fixed = TRUE)
  expect_match(css, "cursor: row-resize", fixed = TRUE)
  # At the narrow breakpoints the divider leaves the layout, so 200% zoom has
  # nothing to drag and the panes stack.
  expect_match(css, ".rcmdr-splitter > .rcmdr-splitter-divider { display: none; }",
               fixed = TRUE)
})

test_that("every working view exposes its split pane", {
  html <- htmltools::renderTags(chart_builder_ui())$html
  expect_match(html, 'data-rcmdr-split="chart_layout"', fixed = TRUE)
  html <- as.character(data_studio_ui())
  expect_match(html, 'data-rcmdr-split="data_layout"', fixed = TRUE)
  html <- as.character(report_studio_ui())
  expect_match(html, 'data-rcmdr-split="report_outline_layout"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-split="report_editor_layout"', fixed = TRUE)
  expect_equal(
    split_pane_ids(),
    c("data_layout", "chart_layout", "report_outline_layout",
      "report_editor_layout")
  )
  app <- readLines(test_path("..", "..", "R", "app.R"))
  expect_true(any(grepl("split_pane_server(split_id, input, state, persist_preferences)",
                        app, fixed = TRUE)))
})

test_that("context menus open from the keyboard and return the focus", {
  js <- as.character(app_js())
  expect_match(js, "data-rcmdr-context-menu", fixed = TRUE)
  expect_match(js, "event.key === 'ContextMenu'", fixed = TRUE)
  expect_match(js, "event.shiftKey && event.key === 'F10'", fixed = TRUE)
  expect_match(js, "rcmdrMenuClose(true)", fixed = TRUE)
  expect_match(js, "setInputValue(input, payload", fixed = TRUE)
  expect_match(js, "event.key === 'ArrowDown'", fixed = TRUE)
  expect_match(js, "event.key === 'Home'", fixed = TRUE)
  # Opening a menu closes the previous one first.
  expect_match(js, "rcmdrMenuOpen(trigger, event.clientX", fixed = TRUE)
  expect_match(js, "Math.min(x, vw - rect.width - 4)", fixed = TRUE)
  expect_match(js, "Math.min(y, vh - rect.height - 4)", fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".rcmdr-context-menu {", fixed = TRUE)
  expect_match(css, "position: fixed", fixed = TRUE)
  expect_match(css, ".rcmdr-context-menu[hidden] { display: none; }",
               fixed = TRUE)
  expect_match(css, ".rcmdr-context-menu-danger", fixed = TRUE)
})

test_that("drag and drop has a keyboard alternative", {
  js <- as.character(app_js())
  expect_match(js, "data-rcmdr-sortable", fixed = TRUE)
  expect_match(js, "data-rcmdr-sortable-id", fixed = TRUE)
  expect_match(js, "data_column_order", fixed = TRUE)
  expect_match(js, "data_drop_file", fixed = TRUE)
  expect_match(js, "FileReader", fixed = TRUE)
  expect_match(js, "rcmdr-dropzone", fixed = TRUE)

  # The same order is reachable from the buttons and from the menu.
  app <- readLines(test_path("..", "..", "R", "app.R"))
  expect_true(any(grepl("move_data_column(-1L)", app, fixed = TRUE)))
  expect_true(any(grepl("move_data_column(1L)", app, fixed = TRUE)))
  chart <- readLines(test_path("..", "..", "R", "chart-studio.R"))
  expect_true(any(grepl("plot_move(state, index", chart, fixed = TRUE)))
})

test_that("the palette moves the active option without losing the query focus", {
  js <- as.character(app_js())
  expect_match(js, "rcmdrPaletteActivate", fixed = TRUE)
  expect_match(js, "aria-activedescendant", fixed = TRUE)
  expect_match(js, "event.key === 'Home'", fixed = TRUE)
  expect_match(js, "event.key === 'End'", fixed = TRUE)
  expect_match(js, "aria-selected", fixed = TRUE)

  html <- as.character(palette_results_ui(data.frame(
    id = c("one", "two"), type = c("menu", "help"),
    label = c("One", "Two"), path = c("Menu", "Help"),
    keywords = c("one", "two"), enabled = c(TRUE, TRUE),
    reason = c("", ""), command = c("cmd1", ""),
    group = c("menu", "help"), favorite = c(FALSE, FALSE),
    recent = c(FALSE, FALSE), stringsAsFactors = FALSE
  )))
  expect_match(html, 'id="palette_listbox"', fixed = TRUE)
  expect_match(html, 'id="palette_option_1"', fixed = TRUE)
  expect_match(html, 'aria-selected="false"', fixed = TRUE)
  expect_match(html, "rcmdr-palette-count", fixed = TRUE)
  expect_match(html, "2 result(s)", fixed = TRUE)
})
