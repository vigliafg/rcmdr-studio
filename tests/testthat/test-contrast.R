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

test_that("the home hero paints its own tokens and stays readable", {
  css <- token_css()
  hero <- regmatches(
    css,
    regexpr("\\.rcmdr-home-hero \\{\\s*background:[^}]*\\}", css,
            perl = TRUE)
  )
  expect_match(hero, "linear-gradient(135deg, var(--rcmdr-hero-from)", fixed = TRUE)
  expect_match(hero, "var(--rcmdr-hero-to) 100%", fixed = TRUE)
  # The accent is light in the dark palettes: it is not a hero surface.
  expect_false(grepl("var(--rcmdr-accent)", hero, fixed = TRUE))

  palettes <- palette_tokens()
  for (name in names(palettes)) {
    palette <- palettes[[name]]
    for (stop in c("--rcmdr-hero-from", "--rcmdr-hero-to")) {
      for (text in c("--rcmdr-on-primary", "--rcmdr-on-primary-muted")) {
        ratio <- contrast_ratio(palette[[text]], palette[[stop]])
        expect_gte(
          ratio, aa_text,
          label = sprintf("%s: %s on %s = %.2f", name, text, stop, ratio)
        )
      }
    }
  }
})

test_that("the topbar badge text is readable on the primary bar", {
  css <- token_css()
  expect_match(css, ".rcmdr-topbar .text-white-50", fixed = TRUE)
  expect_match(css, "color: var(--rcmdr-on-primary-muted) !important;",
               fixed = TRUE)
  # The two hardcoded status colours are gone with the rules that used them.
  expect_false(grepl("#7ee2a8", css, fixed = TRUE))
  expect_false(grepl("#ffb3ad", css, fixed = TRUE))
})

test_that("the measured minimum does not regress below the documented floor", {
  palettes <- palette_tokens()
  floor_of <- function(fg, bg) {
    min(vapply(palettes, function(p) contrast_ratio(p[[fg]], p[[bg]]), 0))
  }
  expect_gte(floor_of("--rcmdr-text", "--rcmdr-surface"), 13)
  expect_gte(floor_of("--rcmdr-muted", "--rcmdr-surface-muted"), 6.3)
  expect_gte(floor_of("--rcmdr-on-primary", "--rcmdr-primary"), 9.4)
  expect_gte(floor_of("--rcmdr-on-primary-muted", "--rcmdr-hero-to"), 5)
  expect_gte(floor_of("--rcmdr-border-strong", "--rcmdr-surface-muted"), 3)
})
