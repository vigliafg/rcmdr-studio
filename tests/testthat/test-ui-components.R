# Shared UI components --------------------------------------------------------

test_that("every icon renders a square svg in the 24x24 grid", {
  paths <- rcmdr_icon_paths()
  expect_gte(length(paths), 10L)
  expect_identical(anyDuplicated(names(paths)), 0L)

  for (name in names(paths)) {
    html <- as.character(rcmdr_icon(name))
    expect_match(html, "<svg", fixed = TRUE)
    expect_match(html, 'viewBox="0 0 24 24"', fixed = TRUE)
    expect_match(html, 'stroke="currentColor"', fixed = TRUE)
    expect_match(html, "rcmdr-icon", fixed = TRUE)
    # A missing path would render "NA" or an empty element.
    expect_false(grepl(">NA<", html, fixed = TRUE))
    expect_gt(nchar(paths[[name]]), 10L)
  }
})

test_that("icons are decorative unless they carry a title", {
  decorative <- as.character(rcmdr_icon("check"))
  expect_match(decorative, 'aria-hidden="true"', fixed = TRUE)
  expect_false(grepl("role=", decorative, fixed = TRUE))
  expect_false(grepl("aria-label", decorative, fixed = TRUE))

  named <- as.character(rcmdr_icon("check", title = "Conferma"))
  expect_match(named, 'role="img"', fixed = TRUE)
  expect_match(named, 'aria-label="Conferma"', fixed = TRUE)
  expect_false(grepl("aria-hidden", named, fixed = TRUE))
})

test_that("the size is applied and unknown names fail loudly", {
  html <- as.character(rcmdr_icon("search", size = 20))
  expect_match(html, 'width="20"', fixed = TRUE)
  expect_match(html, 'height="20"', fixed = TRUE)

  expect_error(rcmdr_icon("not-an-icon"), "arg")
})
