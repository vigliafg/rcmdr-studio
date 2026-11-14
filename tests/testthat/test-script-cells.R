# Script cells, outline and diagnostics --------------------------------------

test_that("plain R cells follow the top-level expressions", {
  cells <- script_cells(workbench_sample_script(), "r")
  expect_equal(nrow(cells), 3L)
  expect_equal(cells$id, c("cell-01", "cell-02", "cell-03"))
  expect_equal(cells$label, c("Data preparation", "Model", ""))
  expect_match(cells$code[[1L]], "D\\$z <- D\\$x \\* 2")
  expect_match(cells$code[[3L]], "summary\\(fit2\\)")
})

test_that("multi-line calls stay in one cell", {
  text <- "model <- lm(\n  y ~ x,\n  data = D\n)\n\nsummary(model)"
  cells <- script_cells(text, "r")
  expect_equal(nrow(cells), 2L)
  expect_equal(cells$start[[1L]], 1L)
  expect_equal(cells$end[[1L]], 4L)
  expect_match(cells$code[[1L]], "data = D")
})

test_that("an unparsable script falls back to blank-line cells", {
  text <- "x <- (1 +\n\ny <- 2"
  cells <- script_cells(text, "r")
  expect_equal(nrow(cells), 2L)
  expect_match(cells$code[[1L]], "x <- \\(1 \\+")
  expect_match(cells$code[[2L]], "y <- 2")
})

test_that("R Markdown cells are the code chunks", {
  text <- paste(
    "---", "title: T", "---", "", "## Section", "",
    "```{r first}", "1 + 1", "```", "", "```{r second}", "2 + 2", "```",
    sep = "\n"
  )
  cells <- script_cells(text, "rmd")
  expect_equal(nrow(cells), 2L)
  expect_equal(cells$label, c("first", "second"))
  expect_equal(cells$code[[1L]], "1 + 1")
})

test_that("cells are located from a zero-based editor row", {
  cells <- script_cells(workbench_sample_script(), "r")
  expect_equal(script_cell_at(cells, 0L)$id[[1L]], "cell-01")
  expect_equal(script_cell_at(cells, 1L)$id[[1L]], "cell-01")
  expect_equal(script_cell_at(cells, 3L)$id[[1L]], "cell-02")
  expect_null(script_cell_at(cells, 100L))
})

test_that("run above and below select whole cells", {
  cells <- script_cells(workbench_sample_script(), "r")
  expect_equal(script_cells_above(cells, 3L)$id, "cell-01")
  expect_equal(script_cells_below(cells, 3L)$id, "cell-03")
  expect_equal(nrow(script_cells_below(cells, 100L)), 0L)
})

test_that("running a cell captures output without touching the document", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  document_set_text(state, workbench_sample_script())
  before <- document_text(state)
  cells <- script_cells(before, "r")
  script_run_cell(state, cells[2, , drop = FALSE])
  entry <- script_run_cell(state, cells[3, , drop = FALSE])
  expect_equal(entry$status, "ok")
  expect_equal(document_text(state), before)
  expect_equal(state$script_outputs[["cell-03"]]$status, "ok")
  expect_true(any(grepl("Coefficients", entry$output)))
  expect_equal(state$history[[1L]]$source, "script")
})

test_that("running above and below executes the selected cells", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  text <- workbench_sample_script()
  document_set_text(state, text)
  cells <- script_cells(text, "r")
  results <- script_run_cells(state, script_cells_above(cells, 5L))
  expect_equal(names(results), c("cell-01", "cell-02"))
  expect_true("z" %in% names(state$env$D))
  results <- script_run_cells(state, script_cells_below(cells, 5L))
  expect_equal(names(results), "cell-03")
})

test_that("a failing cell records the error", {
  state <- workbench_test_state()
  document_registry_ensure(state)
  document_set_text(state, "stop('boom')")
  cells <- script_cells(document_text(state), "r")
  entry <- script_run_cell(state, cells[1, , drop = FALSE])
  expect_equal(entry$status, "error")
  expect_match(entry$error, "boom")
})

test_that("the outline finds comments, sections and functions", {
  text <- paste(
    "# ---- Data ----",
    "x <- 1",
    "## Details",
    "prepare <- function(a) a + 1",
    "# %% Model",
    "fit <- lm(y ~ x, data = D)",
    sep = "\n"
  )
  outline <- script_outline(text, "r")
  expect_equal(outline$title, c("Data", "Details", "prepare()", "Model"))
  expect_equal(outline$level, c(1L, 2L, 2L, 1L))
})

test_that("the outline delegates to the document parser in Rmd mode", {
  text <- "## One\n\n```{r}\n1\n```\n\n### Two\n"
  outline <- script_outline(text, "rmd")
  expect_equal(outline$title, c("One", "Two"))
})

test_that("diagnostics report the parse error position", {
  diagnostics <- script_diagnostics("x <- (1 + ")
  expect_equal(nrow(diagnostics), 1L)
  expect_equal(diagnostics$severity, "error")
  expect_equal(diagnostics$line, 2L)
  expect_match(diagnostics$message, "input|inatteso|unexpected")

  expect_equal(nrow(script_diagnostics("x <- 1")), 0L)
  expect_equal(nrow(script_diagnostics("")), 0L)
})

test_that("formatting is explicit about the styler dependency", {
  result <- script_format_text("x<-1")
  expect_true(is.list(result))
  expect_true(nzchar(result$text))
  if (requireNamespace("styler", quietly = TRUE)) {
    expect_true(result$changed)
  } else {
    expect_false(result$changed)
    expect_match(result$message, "styler")
  }
})

test_that("completion words include objects and columns", {
  state <- workbench_test_state()
  words <- script_completion_words(state)
  expect_true("D" %in% words)
  expect_true("D$y" %in% words)
  expect_true("fit" %in% words)
})
