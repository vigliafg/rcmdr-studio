# Theme × density matrix -------------------------------------------------------
#
# The refresh promises eight themes and two densities that all stay coherent.
# These checks walk the whole matrix in R: every choice is accepted, every
# theme resolves to a palette block the stylesheet defines and to body classes
# the client script applies, density only changes spacing, and the colour pairs
# still clear WCAG AA at every combination.

theme_matrix_palettes <- function(theme) {
  # "system" is not a palette: the client resolves it to light or dark.
  if (identical(theme, "system")) c("light", "dark") else theme
}

theme_matrix_classes <- function(theme) {
  switch(
    theme,
    system = c("rcmdr-light", "rcmdr-dark"),
    light = "rcmdr-light",
    `light-warm` = "rcmdr-light-warm",
    `light-cool` = "rcmdr-light-cool",
    dark = "rcmdr-dark",
    `dark-dim` = c("rcmdr-dark", "rcmdr-dark-dim"),
    `dark-graphite` = c("rcmdr-dark", "rcmdr-dark-graphite"),
    contrast = "rcmdr-contrast"
  )
}

test_that("the matrix is eight themes by two densities", {
  expect_length(ui_themes(), 8L)
  expect_setequal(ui_densities(), c("compact", "comfortable"))

  state <- AppState(env = new.env())
  for (theme in ui_themes()) {
    for (density in ui_densities()) {
      set_ui_theme(state, theme)
      set_ui_density(state, density)
      expect_equal(ui_theme(state), theme, label = theme)
      expect_equal(ui_density(state), density,
                   label = sprintf("%s + %s", theme, density))
    }
  }
})

test_that("every theme resolves to a palette the stylesheet defines", {
  palettes <- palette_tokens()
  for (theme in ui_themes()) {
    blocks <- theme_matrix_palettes(theme)
    expect_true(all(blocks %in% names(palettes)),
                label = sprintf("%s: %s", theme,
                                paste(blocks, collapse = ", ")))
    for (block in blocks) {
      expect_true(all(c("--rcmdr-surface", "--rcmdr-text", "--rcmdr-muted",
                        "--rcmdr-border-strong") %in% names(palettes[[block]])),
                  label = sprintf("%s has the core tokens", block))
    }
  }
})

test_that("the client applies every theme and density as a known class", {
  js <- as.character(app_js())
  for (theme in ui_themes()) {
    for (class in theme_matrix_classes(theme)) {
      expect_match(js, sprintf("'%s'", class), fixed = TRUE,
                   label = sprintf("%s uses %s", theme, class))
    }
  }
  expect_match(js, "'rcmdr-density-comfortable'", fixed = TRUE)
  expect_match(js, "'rcmdr-density-compact'", fixed = TRUE)
  # "system" is resolved against the media query, not left as a body class.
  expect_match(js, "prefers-color-scheme: dark", fixed = TRUE)
})

test_that("density changes spacing and never a colour", {
  css <- as.character(app_css())
  compact <- regmatches(
    css, regexpr("body \\{\\s*--rcmdr-field-gap:[^}]*\\}", css, perl = TRUE)
  )
  comfortable <- regmatches(
    css, regexpr("body\\.rcmdr-density-comfortable \\{[^}]*\\}", css,
                 perl = TRUE)
  )
  tokens <- function(block) {
    pairs <- regmatches(
      block, gregexpr("--rcmdr-[a-z0-9-]+\\s*:", block, perl = TRUE)
    )[[1L]]
    trimws(sub("\\s*:$", "", pairs))
  }
  spacing <- c("--rcmdr-field-gap", "--rcmdr-label-size",
               "--rcmdr-label-gap", "--rcmdr-control-size",
               "--rcmdr-control-pad", "--rcmdr-control-h",
               "--rcmdr-section-gap", "--rcmdr-help-size", "--rcmdr-space")
  expect_true(all(tokens(comfortable) %in% spacing),
              label = "the comfortable block only sets spacing tokens")
  # Both heights exist and comfortable is the taller one.
  expect_match(compact, "--rcmdr-control-h: 2.125rem", fixed = TRUE)
  expect_match(comfortable, "--rcmdr-control-h: 2.5rem", fixed = TRUE)
  expect_match(comfortable, "--rcmdr-label-size: var(--rcmdr-text-md)",
               fixed = TRUE)
})

test_that("text and controls keep AA contrast at every theme and density", {
  palettes <- palette_tokens()
  pairs <- list(
    c("--rcmdr-text", "--rcmdr-surface"),
    c("--rcmdr-muted", "--rcmdr-surface"),
    c("--rcmdr-muted", "--rcmdr-surface-muted"),
    c("--rcmdr-on-primary", "--rcmdr-primary")
  )
  for (theme in ui_themes()) {
    for (density in ui_densities()) {
      for (block in theme_matrix_palettes(theme)) {
        palette <- palettes[[block]]
        for (pair in pairs) {
          ratio <- contrast_ratio(palette[[pair[1]]], palette[[pair[2]]])
          expect_gte(
            ratio, 4.5,
            label = sprintf("%s + %s: %s on %s = %.2f", theme, density,
                            pair[1], pair[2], ratio)
          )
        }
        for (surface in c("--rcmdr-surface", "--rcmdr-surface-muted")) {
          ratio <- contrast_ratio(palette[["--rcmdr-border-strong"]],
                                  palette[[surface]])
          expect_gte(
            ratio, 3,
            label = sprintf("%s + %s: border on %s = %.2f", theme, density,
                            surface, ratio)
          )
        }
      }
    }
  }
})
