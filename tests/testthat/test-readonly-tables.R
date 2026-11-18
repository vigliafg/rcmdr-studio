test_that("table_scroll() is a named, focusable region", {
  html <- as.character(table_scroll(
    label = "Model comparison",
    htmltools::tags$table(htmltools::tags$tr(htmltools::tags$td("x")))
  ))
  expect_match(html, 'class="rcmdr-table-scroll"', fixed = TRUE)
  expect_match(html, 'role="region"', fixed = TRUE)
  expect_match(html, 'tabindex="0"', fixed = TRUE)
  expect_match(html, 'aria-label="Model comparison"', fixed = TRUE)
  expect_match(html, "<table>", fixed = TRUE)
})

test_that("the models dashboard wraps its native table", {
  state <- workbench_test_state()
  html <- htmltools::renderTags(models_dashboard_ui(state))$html
  expect_match(html, "rcmdr-table-scroll", fixed = TRUE)
  expect_match(html, 'role="region"', fixed = TRUE)
  expect_match(html, 'aria-label="Model comparison"', fixed = TRUE)
  expect_match(html, "rcmdr-models-table", fixed = TRUE)
  # The table keeps its native semantics.
  expect_match(html, "<table", fixed = TRUE)
  expect_match(html, "<thead>", fixed = TRUE)
})

test_that("read-only tables share the sticky header and row rhythm", {
  css <- as.character(app_css())
  expect_match(css, ".rcmdr-table thead th,", fixed = TRUE)
  expect_match(css, ".rcmdr-models-table thead th,", fixed = TRUE)
  expect_match(css, ".rcmdr-help-body thead th {", fixed = TRUE)
  expect_match(css, "position: sticky; top: 0; z-index: 1;", fixed = TRUE)
  expect_match(css, "height: var(--rcmdr-table-row-h);", fixed = TRUE)
  expect_match(css, ".rcmdr-table-scroll {", fixed = TRUE)
  expect_match(css, "max-height: 60vh; overflow: auto;", fixed = TRUE)
  expect_match(css, ".rcmdr-help-body { overflow-x: auto; }", fixed = TRUE)
})

test_that("the reactable gate stayed closed", {
  description <- readLines(test_path("..", "..", "DESCRIPTION"))
  expect_false(any(grepl("reactable", description, fixed = TRUE)))
  expect_false(any(grepl("reactR", description, fixed = TRUE)))
  sources <- list.files(test_path("..", "..", "R"), pattern = "[.]R$",
                        full.names = TRUE)
  hits <- unlist(lapply(sources, function(path) {
    grepl("reactable::|reactR::", readLines(path, warn = FALSE), fixed = TRUE)
  }))
  expect_false(any(hits))

  qa <- readLines(test_path("..", "..", "docs", "upgrades", "QA-WIDGETS.md"),
                  warn = FALSE)
  gate <- paste(qa, collapse = "\n")
  expect_match(gate, "reactable", fixed = TRUE)
  expect_match(gate, "3,3 MB", fixed = TRUE)
  expect_match(gate, "gate non passa", fixed = TRUE)
})
