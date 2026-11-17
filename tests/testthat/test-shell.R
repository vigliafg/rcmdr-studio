# Studio shell ----------------------------------------------------------------

test_that("the topbar brands the application and names its selects", {
  html <- as.character(app_topbar_ui())
  expect_match(html, "role=\"banner\"", fixed = TRUE)
  expect_match(html, 'class="rcmdr-brand-mark"', fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  # The selects show their value, not a label; the accessible name is hidden.
  expect_match(html, 'class="visually-hidden">Language', fixed = TRUE)
  expect_match(html, 'class="visually-hidden">Theme', fixed = TRUE)
  expect_match(html, "btn-sm btn-outline-light", fixed = TRUE)
})

test_that("the sidebar search field is named", {
  html <- as.character(app_ui())
  expect_match(html, 'class="visually-hidden">Search menus', fixed = TRUE)
  expect_match(html, 'id="menu_search"', fixed = TRUE)
})

test_that("the status bar is a row of facts, not of pipes", {
  css <- as.character(app_css())
  expect_match(css, ".rcmdr-statusbar {\n      display: flex;", fixed = TRUE)
  expect_match(css,
               ".rcmdr-status-item + .rcmdr-status-item {\n      padding-left: .6rem; border-left: 1px solid var(--rcmdr-border);",
               fixed = TRUE)

  skip_if_not_installed("shiny")
  shiny::testServer(app_server(new.env(parent = globalenv())), {
    html <- htmltools::renderTags(output$statusbar)$html
    expect_match(html, "rcmdr-status-item", fixed = TRUE)
    expect_match(html, "rcmdr-badge", fixed = TRUE)
    # The separator is a border: no pipe character in the live region.
    expect_false(grepl("|", html, fixed = TRUE))
  })
})

test_that("the main tab strip uses the primary pair for the active view", {
  css <- as.character(app_css())
  block <- regmatches(css, regexpr("#main_tabs \\.nav-link\\.active \\{[^}]*\\}",
                                   css))
  expect_match(block, "background: var(--rcmdr-primary);", fixed = TRUE)
  expect_match(block, "color: var(--rcmdr-on-primary);", fixed = TRUE)
  expect_false(grepl("box-shadow", block, fixed = TRUE))
  # The strip is a segmented control, so its boundary is the strong one.
  strip <- regmatches(css, regexpr("#main_tabs\\.nav-tabs \\{[^}]*\\}", css))
  expect_match(strip, "border: 1px solid var(--rcmdr-border-strong);",
               fixed = TRUE)
  expect_match(strip, "border-radius: var(--rcmdr-radius-pill);", fixed = TRUE)
})

test_that("classic mode keeps its own tab markup", {
  classic <- as.character(main_tabs_ui("classic"))
  studio <- as.character(main_tabs_ui("studio"))
  for (html in list(classic, studio)) {
    expect_match(html, "nav nav-tabs shiny-tab-input", fixed = TRUE)
    expect_match(html, 'data-value=', fixed = TRUE)
    expect_false(grepl("rcmdr-tabs", html, fixed = TRUE))
  }
})
