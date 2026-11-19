# Orientation layer (Wave 19).

# O2 — visual grammar ---------------------------------------------------------

test_that("every state icon exists and is a small inline SVG", {
  names <- names(rcmdr_icon_paths())
  expect_true(all(c("file", "folder", "arrow", "funnel", "lock", "server",
                    "undo") %in% names))
  for (name in c("file", "folder", "arrow", "funnel", "lock", "server",
                 "undo")) {
    svg <- as.character(rcmdr_icon(name, 14))
    expect_match(svg, "rcmdr-icon", fixed = TRUE)
    expect_match(svg, 'aria-hidden="true"', fixed = TRUE)
    expect_match(svg, "viewBox", fixed = TRUE)
  }
})

test_that("a context chip always carries its text", {
  neutral <- htmltools::renderTags(
    context_chip("filter: a 2", icon = "funnel")
  )$html
  expect_match(neutral, "rcmdr-badge-neutral", fixed = TRUE)
  expect_match(neutral, "filter: a 2", fixed = TRUE)
  expect_match(neutral, "rcmdr-icon", fixed = TRUE)
  # The icon is decorative: the text is the accessible name.
  expect_match(neutral, 'aria-hidden="true"', fixed = TRUE)

  warning <- htmltools::renderTags(
    context_chip("editing disabled: threshold exceeded",
                 icon = "lock", tone = "warning")
  )$html
  expect_match(warning, "rcmdr-badge-warning", fixed = TRUE)
  expect_match(warning, "editing disabled: threshold exceeded", fixed = TRUE)

  accent <- htmltools::renderTags(
    context_chip("Data Studio", tone = "accent")
  )$html
  expect_match(accent, "rcmdr-badge-accent", fixed = TRUE)
  expect_false(grepl("rcmdr-icon", accent, fixed = TRUE))

  expect_error(context_chip("x", icon = "not-an-icon"))
  expect_error(context_chip("x", tone = "purple"))
})

test_that("the chip tones are token pairs, not literal colours", {
  css <- app_asset_text("css", "20-components.css")
  expect_match(css, ".rcmdr-badge-accent", fixed = TRUE)
  expect_match(css, "border-color: var(--rcmdr-accent);", fixed = TRUE)
  accent <- regmatches(
    css, regexpr("\\.rcmdr-badge-accent\\s*\\{[^}]*\\}", css, perl = TRUE)
  )
  expect_false(grepl("#", accent, fixed = TRUE))
  expect_false(grepl("rgb(", accent, fixed = TRUE))
})
