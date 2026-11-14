# Executable cells -----------------------------------------------------------

test_that("running a cell captures its output without editing the document", {
  state <- report_test_state()
  report_sample_document(state)
  text <- document_text(state)
  log_before <- state$log

  result <- report_run_cell(state, "chunk-summary", text, "rmd")
  expect_equal(result$status, "ok")
  expect_true(any(grepl("Min", result$output) | grepl("y", result$output)))
  expect_equal(document_text(state), text)
  expect_equal(state$log, log_before)

  entry <- state$history[[length(state$history)]]
  expect_equal(entry$source, "report")
  expect_equal(state$cell_outputs[["chunk-summary"]]$status, "ok")
})

test_that("a failing cell records the error", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Error",
    text = c("```{r broken}", "stop(\"boom\")", "```")
  )
  result <- report_run_cell(state, "chunk-broken",
                            document_text(state), "rmd")
  expect_equal(result$status, "error")
  expect_match(result$error, "boom")
  expect_equal(report_cell_status(state, "chunk-broken")$status, "error")
})

test_that("missing and empty cells are reported", {
  state <- report_test_state()
  document_create(state, "rmd", "Empty", text = "```{r blank}\n```")
  expect_equal(report_run_cell(state, "missing",
                               document_text(state), "rmd")$status, "missing")
  expect_equal(report_run_cell(state, "chunk-blank",
                               document_text(state), "rmd")$status, "empty")
})

test_that("all cells can run up to a given chunk", {
  state <- report_test_state()
  report_sample_document(state)
  results <- report_run_all_cells(state, document_text(state), "rmd",
                                  up_to = "chunk-summary")
  expect_equal(names(results), "chunk-summary")
  expect_equal(results[[1L]]$status, "ok")
  expect_null(state$cell_outputs[["chunk-second"]])

  results <- report_run_all_cells(state, document_text(state), "rmd")
  expect_equal(length(results), 2L)
})

test_that("a cell plot is captured inline", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Plot",
    text = c("```{r plot}", "plot(D$x, D$y)", "```")
  )
  result <- report_run_cell(state, "chunk-plot",
                            document_text(state), "rmd")
  expect_equal(result$status, "ok")
  expect_false(is.null(result$plot_url))
  expect_equal(length(state$plots) > 0L, TRUE)
})
