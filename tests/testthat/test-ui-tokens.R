# Design tokens ----------------------------------------------------------------

test_that("every palette defines the same tokens", {
  palettes <- palette_tokens()
  expect_setequal(names(palettes), palette_names)

  reference <- sort(names(palettes$light))
  expect_true("--rcmdr-text" %in% reference)
  expect_true("--rcmdr-focus" %in% reference)
  for (name in names(palettes)) {
    expect_identical(sort(names(palettes[[name]])), reference, info = name)
  }
})

test_that("the focus token is the accent of its palette", {
  palettes <- palette_tokens()
  expect_length(palettes, length(palette_names))
  for (name in names(palettes)) {
    expect_identical(
      palettes[[name]][["--rcmdr-focus"]],
      palettes[[name]][["--rcmdr-accent"]]
    )
  }
})

test_that("the type, spacing and radius scales are declared once", {
  css <- token_css()
  for (token in c("--rcmdr-text-xs: .75rem",
                  "--rcmdr-text-sm: .8125rem",
                  "--rcmdr-text-md: .875rem",
                  "--rcmdr-text-lg: 1rem",
                  "--rcmdr-text-xl: 1.35rem",
                  "--rcmdr-text-2xl: 1.65rem",
                  "--rcmdr-weight-normal: 400",
                  "--rcmdr-weight-strong: 600",
                  "--rcmdr-leading-tight: 1.25",
                  "--rcmdr-leading-normal: 1.5",
                  "--rcmdr-leading-ui: 1.4",
                  "--rcmdr-space-1: .25rem",
                  "--rcmdr-space-2: .5rem",
                  "--rcmdr-space-3: .75rem",
                  "--rcmdr-space-4: 1rem",
                  "--rcmdr-space-5: 1.5rem",
                  "--rcmdr-space-6: 2rem",
                  "--rcmdr-radius-xs: .25rem",
                  "--rcmdr-radius-sm: .375rem",
                  "--rcmdr-radius-md: .5rem",
                  "--rcmdr-radius-lg: .75rem",
                  "--rcmdr-radius-pill: 999px",
                  "--rcmdr-focus-width: 2px",
                  "--rcmdr-focus-offset: 2px")) {
    expect_match(css, token, fixed = TRUE)
  }
})

test_that("font sizes and radii always go through a token", {
  css <- token_css()
  sizes <- regmatches(css, gregexpr("font-size\\s*:\\s*[^;}]+", css))[[1]]
  expect_gt(length(sizes), 10L)
  expect_true(all(grepl("var\\(--rcmdr-", sizes)))

  radii <- regmatches(css, gregexpr("border-radius\\s*:\\s*[^;}]+", css))[[1]]
  expect_gt(length(radii), 10L)
  expect_true(all(grepl("var\\(--rcmdr-", radii)))
})

test_that("density resolves to the scale instead of repeating sizes", {
  css <- token_css()
  # Default (compact) block.
  expect_match(css, "--rcmdr-label-size: var(--rcmdr-text-sm);", fixed = TRUE)
  expect_match(css, "--rcmdr-control-size: var(--rcmdr-text-md);", fixed = TRUE)
  expect_match(css, "--rcmdr-help-size: var(--rcmdr-text-xs);", fixed = TRUE)
  expect_match(css, "--rcmdr-control-h: 2.125rem;", fixed = TRUE)
  expect_match(css, "--rcmdr-control-min: var(--rcmdr-control-h);", fixed = TRUE)

  # Comfortable block raises one type step and the control height.
  comfortable <- sub(".*body\\.rcmdr-density-comfortable\\s*\\{([^}]*)\\}.*",
                     "\\1", css)
  expect_match(comfortable, "--rcmdr-label-size: var(--rcmdr-text-md);",
               fixed = TRUE)
  expect_match(comfortable, "--rcmdr-help-size: var(--rcmdr-text-sm);",
               fixed = TRUE)
  expect_match(comfortable, "--rcmdr-control-h: 2.5rem;", fixed = TRUE)
})

test_that("there is a single global focus ring built from the tokens", {
  css <- token_css()
  global <- regmatches(
    css,
    gregexpr("(?m)^\\s*:focus-visible\\s*\\{[^}]*\\}", css, perl = TRUE)
  )[[1]]
  expect_length(global, 1L)
  expect_match(global, "outline: var(--rcmdr-focus-width) solid var(--rcmdr-focus)",
               fixed = TRUE)
  expect_match(global, "outline-offset: var(--rcmdr-focus-offset)",
               fixed = TRUE)

  # Bootstrap's own halo is gone: the ring is the outline above.
  expect_false(grepl("outline: 3px solid var(--rcmdr-accent)", css, fixed = TRUE))
  expect_match(css, "box-shadow: none;", fixed = TRUE)
})
