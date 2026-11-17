# Buttons ---------------------------------------------------------------------

buttons_css <- function() {
  css <- as.character(app_css())
  start <- regexpr("/* Buttons", css, fixed = TRUE)
  stopifnot(start > 0)
  rest <- substring(css, start)
  end <- regexpr(".text-success", rest, fixed = TRUE)
  stopifnot(end > 0)
  substring(rest, 1L, end - 1L)
}

test_that("buttons are sized by the control height and the small variant steps down", {
  css <- as.character(app_css())
  expect_match(css, "--rcmdr-btn-h: var(--rcmdr-control-h);", fixed = TRUE)
  expect_match(css,
               "--rcmdr-btn-h-sm: calc(var(--rcmdr-control-h) - .375rem);",
               fixed = TRUE)

  buttons <- buttons_css()
  expect_match(buttons, "min-height: var(--rcmdr-btn-h);", fixed = TRUE)
  expect_match(buttons, "min-height: var(--rcmdr-btn-h-sm);", fixed = TRUE)
  # A button is centered content, not a block of text.
  expect_match(buttons, "display: inline-flex;", fixed = TRUE)
  expect_match(buttons, "align-items: center;", fixed = TRUE)
  expect_match(buttons, "white-space: nowrap;", fixed = TRUE)
})

test_that("the six roles are defined on the classes the dialogs already use", {
  buttons <- buttons_css()
  for (selector in c(
    "body .btn-primary {",
    "body .btn-outline-primary {",
    "body .btn-outline-secondary,",
    "body .btn-outline-dark,",
    "body .btn-light,",
    "body .btn-default {",
    "body .btn-link {",
    "body .btn-outline-danger {",
    "body .btn-danger {",
    "body .btn-success {",
    "body .btn-warning {",
    "body .btn-outline-light {"
  )) {
    expect_match(buttons, selector, fixed = TRUE)
  }
})

test_that("solid buttons only use a guaranteed text/background pair", {
  buttons <- buttons_css()
  primary <- regmatches(
    buttons,
    regexpr("body \\.btn-primary \\{[^}]*\\}", buttons, perl = TRUE)
  )
  expect_match(primary, "background-color: var(--rcmdr-primary);", fixed = TRUE)
  expect_match(primary, "color: var(--rcmdr-on-primary);", fixed = TRUE)

  # The accent and the status colours are light in the dark palettes, so they
  # may appear as text or as a tint, never as a fill under white text.
  expect_false(grepl("var(--rcmdr-accent);\\s*border-color[^}]*color: #fff",
                     buttons))
  expect_match(buttons, "background-color: var(--rcmdr-err-bg);", fixed = TRUE)
  expect_match(buttons, "background-color: var(--rcmdr-ok-bg);", fixed = TRUE)
  expect_match(buttons, "background-color: var(--rcmdr-warn-bg);", fixed = TRUE)
})

test_that("the button block contains no colour literal", {
  buttons <- buttons_css()
  expect_false(grepl("#[0-9a-fA-F]{3,8}", buttons))
  expect_false(grepl("rgba?\\(", buttons))
})

test_that("disabled buttons are inert in every variant", {
  buttons <- buttons_css()
  disabled <- regmatches(
    buttons,
    regexpr("body \\.btn:disabled[^}]*\\}", buttons, perl = TRUE)
  )
  expect_match(disabled, "color: var(--rcmdr-disabled);", fixed = TRUE)
  expect_match(disabled, "background-color: var(--rcmdr-surface-muted);",
               fixed = TRUE)
  expect_match(disabled, "cursor: not-allowed;", fixed = TRUE)
  expect_match(disabled, "opacity: 1;", fixed = TRUE)
})

test_that("the dark theme no longer carries its own button colours", {
  css <- as.character(app_css())
  expect_false(grepl("body.rcmdr-dark .btn-outline-secondary", css, fixed = TRUE))
  expect_false(grepl("body.rcmdr-dark .btn-danger", css, fixed = TRUE))
  expect_false(grepl("#b42318", css, fixed = TRUE))
})
