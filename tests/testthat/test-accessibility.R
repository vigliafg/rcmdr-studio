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

test_that("the menubar has navigation semantics", {
  html <- as.character(menubar_ui(menu_tree()))
  expect_match(html, "role=\"navigation\"")
  expect_match(html, "aria-label")
  expect_match(html, "<summary>")
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
})

test_that("the status bar is a live region", {
  expect_match(as.character(app_js()), "rcmdr-tab", fixed = TRUE)
  html <- as.character(app_ui())
  expect_match(html, "role=\"status\"")
  expect_match(html, "rcmdr-statusbar")
})
