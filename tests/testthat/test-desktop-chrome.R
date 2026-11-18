# Desktop chrome and density (Wave 18, S7) -----------------------------------

test_that("the Studio chrome uses one height and one radius scale", {
  tokens <- app_asset_text("css", "00-tokens.css")
  expect_match(tokens, "--rcmdr-topbar-h: 2.5rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-menubar-h: 1.75rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-toolbar-h: 2.5rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-radius-xs: .25rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-radius-sm: .375rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-radius-md: .5rem;", fixed = TRUE)
  expect_match(tokens, "--rcmdr-radius-lg: .5rem;", fixed = TRUE)
})

test_that("the desktop rules are confined to the Studio body class", {
  shell <- app_asset_text("css", "10-shell.css")
  expect_match(shell, "body.rcmdr-mode-studio .rcmdr-topbar", fixed = TRUE)
  expect_match(shell, "body.rcmdr-mode-studio .rcmdr-menubar", fixed = TRUE)
  expect_match(shell, "body.rcmdr-mode-studio .rcmdr-view-bar", fixed = TRUE)
  expect_match(shell, "body.rcmdr-mode-studio .rcmdr-toolbar", fixed = TRUE)
  expect_match(shell, "min-height: var(--rcmdr-topbar-h);", fixed = TRUE)
  expect_match(shell, "min-height: var(--rcmdr-menubar-h);", fixed = TRUE)
  expect_match(shell, "min-height: var(--rcmdr-toolbar-h);", fixed = TRUE)
  # Classic keeps its tabset and its own spacing.
  expect_match(shell, "#main_tabs.nav-tabs", fixed = TRUE)
})

test_that("Studio cards are flat and nothing decorative is a gradient", {
  shell <- app_asset_text("css", "10-shell.css")
  views <- app_asset_text("css", "60-views.css")
  tokens <- app_asset_text("css", "00-tokens.css")
  expect_match(shell, "body.rcmdr-mode-studio .rcmdr-home-card", fixed = TRUE)
  expect_match(shell, "box-shadow: none;", fixed = TRUE)
  for (sheet in c(shell, views, tokens)) {
    expect_false(grepl("linear-gradient", sheet, fixed = TRUE))
  }
})

test_that("the client marks the body with the interface mode", {
  js <- paste(as.character(app_js()), collapse = "\n")
  expect_match(js, "rcmdr-ui-mode", fixed = TRUE)
  expect_match(js, "rcmdr-mode-studio", fixed = TRUE)
  expect_match(js, "rcmdr-mode-classic", fixed = TRUE)
})

test_that("the topbar no longer holds the preference selects", {
  html <- as.character(app_topbar_ui())
  expect_false(grepl('id="theme"', html, fixed = TRUE))
  expect_false(grepl('id="language"', html, fixed = TRUE))
  expect_match(html, 'id="topbar_help"', fixed = TRUE)
})

test_that("the Options dialog owns theme, language and density", {
  spec <- get_dialog_spec("Options")
  html <- htmltools::renderTags(spec$ui(AppState(env = new.env()), NULL))$html
  for (id in c("Options_theme", "Options_language", "Options_density")) {
    expect_match(html, sprintf('id="%s"', id), fixed = TRUE)
  }
})

test_that("the hidden preference inputs keep the existing observers alive", {
  html <- as.character(app_ui())
  expect_match(html, 'id="theme"', fixed = TRUE)
  expect_match(html, 'id="language"', fixed = TRUE)
})
