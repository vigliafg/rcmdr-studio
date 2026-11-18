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

test_that("modal_shell() dresses Shiny's shell with the shared chrome", {
  html <- as.character(modal_shell(
    "Keyboard shortcuts", category = "Help", icon = "help",
    htmltools::tags$p("Body"), size = "l",
    primary = htmltools::tags$button("OK"), easyClose = TRUE, close = TRUE
  ))
  # One header and one footer: the shell's own are replaced, not doubled.
  expect_length(regmatches(html, gregexpr('class="modal-header', html))[[1L]], 1L)
  expect_length(regmatches(html, gregexpr('class="modal-footer', html))[[1L]], 1L)
  expect_match(html, 'class="modal-header rcmdr-modal-header"', fixed = TRUE)
  expect_match(html, 'class="modal-footer rcmdr-modal-footer"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-modal-primary"', fixed = TRUE)
  # The dialog is labelled by the heading the component wrote.
  expect_match(html, 'aria-labelledby="rcmdr-modal-title"', fixed = TRUE)
  expect_match(html, 'id="rcmdr-modal-title">Keyboard shortcuts</h4>',
               fixed = TRUE)
  # easyClose keeps Shiny's backdrop and keyboard contract.
  expect_false(grepl('data-bs-backdrop="static"', html, fixed = TRUE))
  expect_match(html, "modal-dialog modal-lg", fixed = TRUE)

  # A dialog without a footer gets no empty one.
  bare <- as.character(modal_shell("Plain", htmltools::tags$p("Body")))
  expect_false(grepl("modal-footer", bare, fixed = TRUE))
  expect_false(grepl("btn-close", bare, fixed = TRUE))

  # easyClose = FALSE keeps the static backdrop and the disabled keyboard.
  static <- as.character(modal_shell("Decide", htmltools::tags$p("Body")))
  expect_match(static, 'data-bs-backdrop="static"', fixed = TRUE)
})

test_that("modal_dismiss_button() keeps the size of its neighbours", {
  html <- as.character(modal_dismiss_button("Chiudi"))
  expect_match(html, 'class="btn btn-sm btn-outline-secondary"', fixed = TRUE)
  expect_match(html, 'data-dismiss="modal"', fixed = TRUE)
  expect_match(html, 'data-bs-dismiss="modal"', fixed = TRUE)
  expect_match(html, ">Chiudi</button>", fixed = TRUE)
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

test_that("settings_accordion() marks every header as a heading", {
  html <- as.character(settings_accordion(
    id = "demo_settings",
    open = "Options",
    settings_panel("Options", htmltools::tags$input(id = "a")),
    settings_panel("Style", htmltools::tags$input(id = "b"))
  ))

  expect_match(html, 'rcmdr-accordion', fixed = TRUE)
  expect_match(html, 'id="demo_settings"', fixed = TRUE)
  # bslib emits a div: the role and the level are what make it navigable.
  expect_equal(
    lengths(regmatches(html, gregexpr('role="heading"', html))), 2L
  )
  expect_equal(
    lengths(regmatches(html, gregexpr('aria-level="3"', html))), 2L
  )
  # Bootstrap's button keeps its own state contract.
  expect_match(html, 'aria-expanded="true"', fixed = TRUE)
  expect_match(html, 'aria-expanded="false"', fixed = TRUE)
  expect_match(html, "aria-controls=", fixed = TRUE)
  # One panel open, the other closed.
  expect_equal(
    lengths(regmatches(html, gregexpr('class="accordion-collapse collapse show"',
                                      html))), 1L
  )
  expect_match(html, 'data-value="Options"', fixed = TRUE)
  expect_match(html, 'data-value="Style"', fixed = TRUE)
})

test_that("settings_panel() composes icon, badge, title and body grid", {
  html <- as.character(settings_accordion(
    settings_panel(
      "Theme", htmltools::tags$input(id = "theme"),
      icon = "sliders", badge = "3"
    )
  ))
  expect_match(html, "rcmdr-accordion-icon", fixed = TRUE)
  expect_match(html, 'class="rcmdr-accordion-title"', fixed = TRUE)
  expect_match(html, "rcmdr-badge", fixed = TRUE)
  expect_match(html, ">3</span>", fixed = TRUE)
  # The body is wrapped in the shared grid, so the fields keep its columns.
  expect_match(html, 'class="rcmdr-field-grid"', fixed = TRUE)

  bare <- as.character(settings_accordion(
    settings_panel("Plain", htmltools::tags$input(id = "plain"), grid = FALSE)
  ))
  expect_false(grepl("rcmdr-field-grid", bare, fixed = TRUE))
})

test_that("settings_accordion() rejects ambiguous contracts", {
  expect_error(
    settings_accordion(
      settings_panel("Same", "a"),
      settings_panel("Same", "b")
    ),
    "unique"
  )
  expect_error(
    settings_accordion(settings_panel("Only", "a"), open = "Missing"),
    "not panels"
  )
  expect_error(
    settings_accordion(settings_panel("Only", "a"), level = 9L),
    "between 1 and 6"
  )
  expect_error(
    settings_panel(htmltools::tags$span("Markup"), "a"),
    "plain `value`"
  )
})

test_that("settings_group() is a titled, non-collapsible group", {
  html <- as.character(settings_group(
    "Axes", htmltools::tags$input(id = "x"), help = "Both axes"
  ))
  expect_match(html, 'class="rcmdr-settings-group"', fixed = TRUE)
  expect_match(html, 'role="heading"', fixed = TRUE)
  expect_match(html, 'aria-level="4"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-field-grid"', fixed = TRUE)
  expect_match(html, "Both axes", fixed = TRUE)
  expect_false(grepl("accordion", html, fixed = TRUE))
})

test_that("help_tip() is a focusable trigger with a named bubble", {
  html <- as.character(help_tip("Short explanation", label = "About alpha"))
  expect_match(html, 'type="button"', fixed = TRUE)
  expect_match(html, "rcmdr-help-tip-trigger", fixed = TRUE)
  expect_match(html, 'aria-label="About alpha"', fixed = TRUE)
  expect_match(html, "bslib-tooltip", fixed = TRUE)
  expect_match(html, "Short explanation", fixed = TRUE)
  # The icon is decorative: the button name carries the meaning.
  expect_match(html, 'aria-hidden="true"', fixed = TRUE)
  expect_match(html, "rcmdr-help-tip", fixed = TRUE)
})

test_that("split_pane() builds a labelled window splitter", {
  html <- as.character(split_pane(
    "unit_split", htmltools::div("left"), htmltools::div("right"),
    initial = 0.4, min = 240, min_second = 200
  ))
  expect_match(html, 'class="rcmdr-splitter rcmdr-splitter-horizontal"',
               fixed = TRUE)
  expect_match(html, 'role="separator"', fixed = TRUE)
  expect_match(html, 'tabindex="0"', fixed = TRUE)
  # Side-by-side panes have a vertical separator, as ARIA defines it.
  expect_match(html, 'aria-orientation="vertical"', fixed = TRUE)
  expect_match(html, 'aria-valuemin="10"', fixed = TRUE)
  expect_match(html, 'aria-valuemax="90"', fixed = TRUE)
  expect_match(html, 'aria-valuenow=', fixed = TRUE)
  expect_match(html, 'aria-valuetext=', fixed = TRUE)
  expect_match(html, 'aria-controls="rcmdr-split-first-unit_split rcmdr-split-second-unit_split"',
               fixed = TRUE)
  expect_match(html, 'data-rcmdr-split-input="unit_split_size"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-split-default="40.00"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-split-min="240"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-split-min-second="200"', fixed = TRUE)
  expect_match(html, "--rcmdr-split-min: 240px;", fixed = TRUE)
  expect_match(html, "rcmdr-splitter-grip", fixed = TRUE)
  expect_match(html, 'aria-hidden="true"', fixed = TRUE)
})

test_that("split_pane() stacks its panes when vertical", {
  html <- as.character(split_pane(
    "stacked", "top", "bottom", orientation = "vertical", initial = 0.3
  ))
  expect_match(html, "rcmdr-splitter-vertical", fixed = TRUE)
  expect_match(html, 'aria-orientation="horizontal"', fixed = TRUE)
  expect_match(html, "top", fixed = TRUE)
  expect_match(html, "bottom", fixed = TRUE)
})

test_that("context_menu() is a labelled, initially hidden menu", {
  html <- as.character(context_menu(
    "demo_menu",
    context_menu_item("First", click = "first_button"),
    context_menu_separator(),
    context_menu_item("Second", input = "demo_action", action = "second"),
    label = "Demo actions"
  ))
  expect_match(html, 'id="demo_menu"', fixed = TRUE)
  expect_match(html, 'role="menu"', fixed = TRUE)
  expect_match(html, 'aria-label="Demo actions"', fixed = TRUE)
  expect_match(html, 'hidden="hidden"', fixed = TRUE)
  expect_match(html, 'tabindex="-1"', fixed = TRUE)
  expect_match(html, 'role="menuitem"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-click="first_button"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-input="demo_action"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-action="second"', fixed = TRUE)
  expect_match(html, 'role="separator"', fixed = TRUE)
})

test_that("a context-menu target is focusable and names its menu", {
  html <- as.character(context_menu_target(
    menu = "demo_menu", payload = '{"index":3}', label = "Chart actions",
    class = "demo-card", htmltools::tags$h6("Card")
  ))
  expect_match(html, 'class="rcmdr-context-target demo-card"', fixed = TRUE)
  expect_match(html, 'tabindex="0"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-context-menu="demo_menu"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-payload="{&quot;index&quot;:3}"',
               fixed = TRUE)
  expect_match(html, 'aria-haspopup="menu"', fixed = TRUE)
  expect_match(html, 'aria-expanded="false"', fixed = TRUE)
  expect_match(html, 'aria-label="Chart actions"', fixed = TRUE)
})

test_that("tabs_strip() attaches one menu per tab", {
  html <- as.character(tabs_strip(
    "doc_tab", c("One" = "one"), payload = TRUE, closable = TRUE,
    menus = list(context_menu(
      "doc_tab_menu_one",
      context_menu_item("Close", input = "doc_tab", action = "close")
    ))
  ))
  expect_match(html, 'data-rcmdr-context-menu="doc_tab_menu_one"', fixed = TRUE)
  expect_match(html, 'data-rcmdr-menu-payload="{&quot;id&quot;:&quot;one&quot;}"',
               fixed = TRUE)
  expect_match(html, 'id="doc_tab_menu_one"', fixed = TRUE)
  expect_error(
    tabs_strip("doc_tab", c("One" = "one", "Two" = "two"), payload = TRUE,
               menus = list(context_menu("only_one"))),
    "one menu per tab"
  )
})
