# Contrast --------------------------------------------------------------------
#
# The table in docs/upgrades/UI-TOKENS.md is an assertion: these tests
# recompute it from the tokens in app_css(), so a new palette cannot enter
# without its numbers.

aa_text <- 4.5
aa_large <- 3
ui_component <- 3

test_that("every text pair meets WCAG AA on every palette", {
  palettes <- palette_tokens()
  pairs <- list(
    c("--rcmdr-text", "--rcmdr-surface"),
    c("--rcmdr-text", "--rcmdr-surface-muted"),
    c("--rcmdr-text", "--rcmdr-surface-sunken"),
    c("--rcmdr-text", "--rcmdr-bg"),
    c("--rcmdr-heading", "--rcmdr-surface"),
    c("--rcmdr-heading", "--rcmdr-bg"),
    c("--rcmdr-muted", "--rcmdr-surface"),
    c("--rcmdr-muted", "--rcmdr-surface-muted"),
    c("--rcmdr-muted", "--rcmdr-surface-sunken"),
    c("--rcmdr-muted", "--rcmdr-bg"),
    c("--rcmdr-link", "--rcmdr-surface"),
    c("--rcmdr-on-primary", "--rcmdr-primary"),
    c("--rcmdr-on-primary-muted", "--rcmdr-primary"),
    c("--rcmdr-accent", "--rcmdr-surface"),
    c("--rcmdr-danger", "--rcmdr-surface"),
    c("--rcmdr-warning", "--rcmdr-surface"),
    c("--rcmdr-success", "--rcmdr-surface"),
    c("--rcmdr-ok-fg", "--rcmdr-ok-bg"),
    c("--rcmdr-warn-fg", "--rcmdr-warn-bg"),
    c("--rcmdr-err-fg", "--rcmdr-err-bg")
  )
  for (name in names(palettes)) {
    palette <- palettes[[name]]
    for (pair in pairs) {
      ratio <- contrast_ratio(palette[[pair[1]]], palette[[pair[2]]])
      expect_gte(
        ratio, aa_text,
        label = sprintf("%s: %s on %s = %.2f", name, pair[1], pair[2], ratio)
      )
    }
  }
})

test_that("control boundaries and focus rings reach 3:1", {
  palettes <- palette_tokens()
  surfaces <- c("--rcmdr-surface", "--rcmdr-surface-muted",
                "--rcmdr-surface-sunken")
  for (name in names(palettes)) {
    palette <- palettes[[name]]
    expect_true("--rcmdr-border-strong" %in% names(palette), info = name)
    for (surface in surfaces) {
      ratio <- contrast_ratio(palette[["--rcmdr-border-strong"]],
                              palette[[surface]])
      expect_gte(
        ratio, ui_component,
        label = sprintf("%s: border-strong on %s = %.2f", name, surface, ratio)
      )
    }
    focus <- contrast_ratio(palette[["--rcmdr-focus"]], palette[["--rcmdr-surface"]])
    expect_gte(focus, ui_component,
               label = sprintf("%s: focus on surface = %.2f", name, focus))
  }
})

test_that("the Studio home has no gradient and needs no hero palette", {
  tokens <- token_css()
  expect_false(grepl("--rcmdr-hero-", tokens, fixed = TRUE))
  for (file in c("60-views.css", "10-shell.css")) {
    sheet <- app_asset_text("css", file)
    expect_false(grepl("linear-gradient", sheet, fixed = TRUE),
                 label = sprintf("%s paints no gradient surface", file))
  }
})

test_that("the topbar value text is readable on the primary bar", {
  css <- token_css()
  expect_match(css, ".rcmdr-topbar-value-empty {", fixed = TRUE)
  expect_match(css,
               "color: var(--rcmdr-on-primary-muted); font-weight: var(--rcmdr-weight-normal);",
               fixed = TRUE)
  expect_match(css, ".rcmdr-topbar-value {", fixed = TRUE)
  # The two hardcoded status colours are gone with the rules that used them.
  expect_false(grepl("#7ee2a8", css, fixed = TRUE))
  expect_false(grepl("#ffb3ad", css, fixed = TRUE))

  # Measure the pair instead of trusting the rule: every palette keeps the
  # muted value at AA on the primary bar.
  palettes <- palette_tokens()
  for (name in names(palettes)) {
    palette <- palettes[[name]]
    ratio <- contrast_ratio(palette[["--rcmdr-on-primary-muted"]],
                            palette[["--rcmdr-primary"]])
    expect_gte(
      ratio, aa_text,
      label = sprintf("%s: on-primary-muted on primary = %.2f", name, ratio)
    )
  }
})

test_that("the measured minimum does not regress below the documented floor", {
  palettes <- palette_tokens()
  floor_of <- function(fg, bg) {
    min(vapply(palettes, function(p) contrast_ratio(p[[fg]], p[[bg]]), 0))
  }
  expect_gte(floor_of("--rcmdr-text", "--rcmdr-surface"), 13)
  expect_gte(floor_of("--rcmdr-muted", "--rcmdr-surface-muted"), 6.3)
  expect_gte(floor_of("--rcmdr-on-primary", "--rcmdr-primary"), 9.4)
  expect_gte(floor_of("--rcmdr-on-primary-muted", "--rcmdr-primary"), 5)
  expect_gte(floor_of("--rcmdr-border-strong", "--rcmdr-surface-muted"), 3)
})

test_that("the component pairs introduced in U2 meet AA", {
  palettes <- palette_tokens()
  pairs <- list(
    c("badge info", "--rcmdr-link", "--rcmdr-surface-muted"),
    c("dialog icon", "--rcmdr-accent", "--rcmdr-surface-muted"),
    c("brand mark", "--rcmdr-primary", "--rcmdr-on-primary-muted"),
    c("tab hover", "--rcmdr-heading", "--rcmdr-hover")
  )
  for (name in names(palettes)) {
    palette <- palettes[[name]]
    for (pair in pairs) {
      ratio <- contrast_ratio(palette[[pair[2]]], palette[[pair[3]]])
      expect_gte(
        ratio, aa_text,
        label = sprintf("%s: %s (%s on %s) = %.2f",
                        name, pair[1], pair[2], pair[3], ratio)
      )
    }
  }
})
