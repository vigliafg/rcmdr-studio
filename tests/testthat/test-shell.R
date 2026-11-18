# Studio shell ----------------------------------------------------------------

test_that("the topbar brands the application and keeps only session facts", {
  html <- as.character(app_topbar_ui())
  expect_match(html, 'class="rcmdr-topbar"', fixed = TRUE)
  expect_match(html, "role=\"banner\"", fixed = TRUE)
  expect_match(html, 'class="rcmdr-brand"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-brand-title"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-brand-mark"', fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  # The controls are one flex list, not a row of Bootstrap utilities.
  expect_match(html, 'class="rcmdr-topbar-controls"', fixed = TRUE)
  expect_match(html, "rcmdr-topbar-link", fixed = TRUE)
  expect_match(html, 'id="topbar_help"', fixed = TRUE)
  expect_match(html, "btn-sm btn-outline-light", fixed = TRUE)
  # Theme, language and density moved to View > Preferences (Options).
  expect_false(grepl('id="theme"', html, fixed = TRUE))
  expect_false(grepl('id="language"', html, fixed = TRUE))
  expect_false(grepl('id="density"', html, fixed = TRUE))
})

test_that("View > Preferences opens the Options dialog", {
  leaves <- menu_leaves(menu_tree())
  entry <- leaves[leaves$command == "preferencesOpen", , drop = FALSE]
  expect_equal(nrow(entry), 1L)
  expect_equal(entry$path[[1L]], "View > Preferences...")
})

test_that("the shell carries no hand-written Bootstrap layout classes", {
  # app_ui() also contains bslib's own container wrapper; only the classes we
  # write are checked.
  html <- as.character(app_ui())
  classes <- unlist(regmatches(
    html,
    gregexpr('class="[^"]*"', html)
  ))
  classes <- unlist(strsplit(sub('^class="', "", sub('"$', "", classes)), "\\s+"))
  for (class in c("d-flex", "gap-2", "ms-auto", "px-3", "py-2", "py-3",
                  "fs-5", "badge-box", "text-white", "text-warning",
                  "text-white-50", "col-lg-3", "col-lg-9", "col-xl-2",
                  "col-xl-10")) {
    expect_false(class %in% classes,
                 label = sprintf("shell still writes the %s utility", class))
  }
  expect_match(html, 'class="rcmdr-shell-body"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-main"', fixed = TRUE)
  expect_match(html, 'class="rcmdr-menu-actions"', fixed = TRUE)
})

test_that("the shell grid has one column above the sidebar breakpoint", {
  css <- as.character(app_css())
  body <- regmatches(css, regexpr("\\.rcmdr-shell-body \\{[^}]*\\}", css))
  expect_match(body, "display: grid;", fixed = TRUE)
  expect_match(body,
               "grid-template-columns: minmax(14rem, 17rem) minmax(0, 1fr);",
               fixed = TRUE)

  # Below the large breakpoint the sidebar sits above the view and becomes a
  # short panel; its max-height only wins if the old min-height is cleared.
  narrow <- regmatches(
    css,
    regexpr("@media \\(max-width: 991\\.98px\\) \\{[^@]*\\.rcmdr-shell-body[^@]*\\}",
            css, perl = TRUE)
  )
  expect_match(narrow, "grid-template-columns: minmax(0, 1fr);",
               fixed = TRUE)
  expect_match(narrow, "min-height: 0; max-height: 46vh;", fixed = TRUE)
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

test_that("classic keeps its tabs and studio uses the workspace switcher", {
  classic <- as.character(main_tabs_ui("classic"))
  expect_match(classic, "nav nav-tabs shiny-tab-input", fixed = TRUE)
  expect_match(classic, 'data-value=', fixed = TRUE)
  expect_false(grepl("rcmdr-tabs", classic, fixed = TRUE))

  studio <- as.character(main_tabs_ui("studio"))
  expect_match(studio, "workspace_switcher_ui", fixed = TRUE)
  expect_match(studio, "workspace_layout", fixed = TRUE)
  expect_match(studio, 'id="main_tabs"', fixed = TRUE)
  expect_false(grepl("nav nav-tabs shiny-tab-input", studio, fixed = TRUE))

  switcher <- as.character(workspace_view_switcher("home"))
  expect_match(switcher, "rcmdr-view-switcher", fixed = TRUE)
  expect_match(switcher, 'data-rcmdr-view="data"', fixed = TRUE)
})
