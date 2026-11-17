# Shared UI components --------------------------------------------------------

test_that("every icon renders a square svg in the 24x24 grid", {
  paths <- rcmdr_icon_paths()
  expect_gte(length(paths), 10L)
  expect_identical(anyDuplicated(names(paths)), 0L)

  for (name in names(paths)) {
    html <- as.character(rcmdr_icon(name))
    expect_match(html, "<svg", fixed = TRUE)
    expect_match(html, 'viewBox="0 0 24 24"', fixed = TRUE)
    expect_match(html, 'stroke="currentColor"', fixed = TRUE)
    expect_match(html, "rcmdr-icon", fixed = TRUE)
    # A missing path would render "NA" or an empty element.
    expect_false(grepl(">NA<", html, fixed = TRUE))
    expect_gt(nchar(paths[[name]]), 10L)
  }
})

test_that("icons are decorative unless they carry a title", {
  decorative <- as.character(rcmdr_icon("check"))
  expect_match(decorative, 'aria-hidden="true"', fixed = TRUE)
  expect_false(grepl("role=", decorative, fixed = TRUE))
  expect_false(grepl("aria-label", decorative, fixed = TRUE))

  named <- as.character(rcmdr_icon("check", title = "Conferma"))
  expect_match(named, 'role="img"', fixed = TRUE)
  expect_match(named, 'aria-label="Conferma"', fixed = TRUE)
  expect_false(grepl("aria-hidden", named, fixed = TRUE))
})

test_that("the size is applied and unknown names fail loudly", {
  html <- as.character(rcmdr_icon("search", size = 20))
  expect_match(html, 'width="20"', fixed = TRUE)
  expect_match(html, 'height="20"', fixed = TRUE)

  expect_error(rcmdr_icon("not-an-icon"), "arg")
})

test_that("toolbar() keeps its two ends and is labelled when asked", {
  html <- as.character(toolbar(
    htmltools::tags$span(id = "middle"),
    left = htmltools::tags$span(id = "first"),
    right = htmltools::tags$span(id = "last"),
    label = "Filters"
  ))
  expect_match(html, 'class="rcmdr-toolbar"', fixed = TRUE)
  expect_match(html, 'role="toolbar"', fixed = TRUE)
  expect_match(html, 'aria-label="Filters"', fixed = TRUE)
  # right is the pushed end.
  expect_match(html, 'class="rcmdr-toolbar-end"', fixed = TRUE)
  expect_false(grepl("d-flex", html, fixed = TRUE))
  expect_lt(regexpr('id="first"', html, fixed = TRUE),
            regexpr('id="middle"', html, fixed = TRUE))
  expect_lt(regexpr('id="middle"', html, fixed = TRUE),
            regexpr('id="last"', html, fixed = TRUE))

  silent <- as.character(toolbar(htmltools::tags$span("x")))
  expect_false(grepl("role=", silent, fixed = TRUE))
  # The old name is the same component.
  expect_identical(as.character(studio_toolbar(htmltools::tags$span("x"))),
                   silent)
})

test_that("badge() colours a label without making colour the message", {
  ok <- as.character(badge("ok", "ok", icon = "check"))
  expect_match(ok, 'class="rcmdr-badge rcmdr-badge-ok"', fixed = TRUE)
  expect_match(ok, "\\bok\\b")
  # The icon is decorative: the word carries the meaning.
  expect_match(ok, 'aria-hidden="true"', fixed = TRUE)
  expect_false(grepl("aria-label", ok, fixed = TRUE))

  expect_match(as.character(badge("x", "warning")), "rcmdr-badge-warning",
               fixed = TRUE)
  expect_match(as.character(badge("x", "error")), "rcmdr-badge-error",
               fixed = TRUE)
  expect_match(as.character(badge("x")), "rcmdr-badge-neutral", fixed = TRUE)
  expect_error(badge("x", "purple"))
})

test_that("modal_header() carries the icon, the category and the close button", {
  html <- as.character(modal_header(
    "Options", category = "Tools", icon = "sliders",
    close_label = "Chiudi", id = "options-title"
  ))
  expect_match(html, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-dialog-icon"', fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  expect_match(html, 'id="options-title">Options</h4>', fixed = TRUE)
  expect_match(html, 'class="rcmdr-dialog-category">Tools', fixed = TRUE)
  expect_match(html, 'class="btn-close"', fixed = TRUE)
  expect_match(html, 'data-bs-dismiss="modal"', fixed = TRUE)
  expect_match(html, 'aria-label="Chiudi"', fixed = TRUE)

  bare <- as.character(modal_header("Plain", close = FALSE))
  expect_false(grepl("btn-close", bare, fixed = TRUE))
  expect_false(grepl("rcmdr-dialog-icon", bare, fixed = TRUE))
})

test_that("modal_footer() puts the primary action last and on the right", {
  html <- as.character(modal_footer(
    htmltools::tags$button("Cancel"),
    primary = htmltools::tags$button("OK")
  ))
  expect_match(html, 'class="modal-footer rcmdr-modal-footer"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-modal-primary"', fixed = TRUE)
  expect_lt(regexpr(">Cancel<", html, fixed = TRUE),
            regexpr(">OK<", html, fixed = TRUE))
})

test_that("tabs_strip() is a labelled group of toggle buttons", {
  html <- as.character(tabs_strip(
    "doc_tab", c("One" = "one", "Two" = "two"), selected = "two",
    label = "Documents"
  ))
  expect_match(html, 'class="rcmdr-tabs"', fixed = TRUE)
  expect_match(html, 'role="group"', fixed = TRUE)
  expect_match(html, 'aria-label="Documents"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-tabs-item active"', fixed = TRUE)
  expect_match(html, 'aria-pressed="true"', fixed = TRUE)
  expect_match(html, 'aria-pressed="false"', fixed = TRUE)
  expect_match(html, 'data-value="two"', fixed = TRUE)
  # The onclick sets the input; htmltools escapes the quotes, so check the
  # contract (id, value, priority) rather than the exact source.
  expect_match(html, "Shiny.setInputValue", fixed = TRUE)
  expect_match(html, "doc_tab", fixed = TRUE)
  expect_match(html, "priority", fixed = TRUE)
  # No ARIA tab pattern without arrow-key navigation.
  expect_false(grepl('role="tab"', html, fixed = TRUE))
  expect_identical(tabs_strip("x", character()), NULL)

  expect_error(tabs_strip("x", c("one", "two")), "named")
  expect_error(tabs_strip("x", c("a" = "a'b")), "identifiers")
})

test_that("the components are styled by tokens", {
  css <- as.character(app_css())
  for (selector in c(
    ".rcmdr-badge {", ".rcmdr-badge-ok {", ".rcmdr-badge-warning {",
    ".rcmdr-badge-error {", ".rcmdr-tabs-item.active {",
    ".rcmdr-dialog-icon {", ".rcmdr-modal-primary {"
  )) {
    expect_match(css, selector, fixed = TRUE)
  }
  # A filled badge or tab uses a pair, never a raw colour.
  block <- regmatches(css, regexpr("\\.rcmdr-tabs-item\\.active \\{[^}]*\\}",
                                   css))
  expect_match(block, "background: var(--rcmdr-primary);", fixed = TRUE)
  expect_match(block, "color: var(--rcmdr-on-primary);", fixed = TRUE)
})

test_that("action_row() wraps its actions with the token gap", {
  html <- as.character(action_row(
    htmltools::tags$button(id = "a", "A"),
    htmltools::tags$button(id = "b", "B")
  ))
  expect_match(html, 'class="rcmdr-actions"', fixed = TRUE)
  expect_lt(regexpr('id="a"', html, fixed = TRUE),
            regexpr('id="b"', html, fixed = TRUE))

  tight <- as.character(action_row(htmltools::tags$button("x"), tight = TRUE))
  expect_match(tight, 'class="rcmdr-actions rcmdr-actions-tight"',
               fixed = TRUE)

  # The dialog helper is the same component.
  expect_identical(as.character(button_row(htmltools::tags$span("x"))),
                   as.character(action_row(htmltools::tags$span("x"))))
})

test_that("note() is secondary text in both shapes", {
  block <- as.character(note("One line"))
  expect_match(block, '<p class="rcmdr-note">One line</p>', fixed = TRUE)

  inline <- as.character(note("One line", inline = TRUE))
  expect_match(inline, "rcmdr-note-inline", fixed = TRUE)
  expect_match(inline, "<span", fixed = TRUE)
})

test_that("card_head() keeps the title and one end slot on a line", {
  html <- as.character(card_head(
    htmltools::tags$h6("Title"),
    htmltools::tags$span(id = "end", "x")
  ))
  expect_match(html, 'class="rcmdr-card-head"', fixed = TRUE)
  expect_lt(regexpr("Title", html, fixed = TRUE),
            regexpr('id="end"', html, fixed = TRUE))
  # Without an end slot the heading is still one block.
  solo <- as.character(card_head(htmltools::tags$h6("Title")))
  expect_match(solo, 'class="rcmdr-card-head"', fixed = TRUE)
})

test_that("tabs_strip() can close a tab and send an action payload", {
  html <- as.character(tabs_strip(
    "doc_tab", c("One" = "one", "Two" = "two"), selected = "one",
    label = "Documents", payload = TRUE, closable = TRUE,
    close_label = "Close"
  ))
  # The payload carries the value and the action, not a bare value.
  expect_match(html, "{id: &#39;one&#39;, action: &#39;activate&#39;}",
               fixed = TRUE)
  expect_match(html, "{id: &#39;two&#39;, action: &#39;close&#39;}", fixed = TRUE)
  # The close button is named after its tab, not just "Close".
  expect_match(html, 'aria-label="Close Two"', fixed = TRUE)
  expect_match(html, "rcmdr-doc-close", fixed = TRUE)

  # A rich label keeps the plain name for the close button.
  rich <- as.character(tabs_strip(
    "doc_tab", c("One" = "one"), labels = list(htmltools::tags$span("Rich")),
    payload = TRUE, closable = TRUE
  ))
  expect_match(rich, "<span>Rich</span>", fixed = TRUE)
  expect_match(rich, 'aria-label="Close One"', fixed = TRUE)
})
