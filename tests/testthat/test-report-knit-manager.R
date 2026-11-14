# Knit manager ---------------------------------------------------------------

test_that("format availability comes with a readable reason", {
  expect_equal(document_format_reason("html", "rmd"),
               if (document_format_available("html", "rmd")) "" else
                 document_format_reason("html", "rmd"))
  if (!document_format_available("pdf", "rmd")) {
    expect_match(document_format_reason("pdf", "rmd"), "PDF")
  }
  expect_match(document_format_reason("word", "rnw"), "LaTeX")
})

test_that("a successful knit is recorded in the history", {
  skip_if_not(document_format_available("html", "rmd"),
              "Pandoc or rmarkdown not available")
  state <- report_test_state()
  report_sample_document(state)
  result <- document_knit(state, "html")
  expect_true(file.exists(result$file))
  expect_equal(result$format, "html")
  expect_equal(length(state$knit_history), 1L)
  entry <- state$knit_history[[1L]]
  expect_equal(entry$status, "ok")
  expect_equal(entry$format, "html")
  expect_true(entry$duration_ms >= 0)
  expect_equal(state$knit_result$file, result$file)
})

test_that("a failed knit is recorded and rethrown", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Broken",
    text = c("---", "title: Broken", "---", "",
             "```{r}", "stop(\"knit boom\")", "```")
  )
  if (!document_format_available("html", "rmd")) {
    expect_error(document_knit(state, "html"), "not available")
  } else {
    expect_error(document_knit(state, "html"), "knit boom|Knit failed")
  }
  expect_equal(length(state$knit_history), 1L)
  expect_equal(state$knit_history[[1L]]$status, "error")
  expect_true(nzchar(state$knit_history[[1L]]$error))
})

test_that("plain and empty documents are refused", {
  state <- report_test_state()
  expect_error(document_knit(state, "html"), "Switch to")
  expect_equal(state$knit_history[[1L]]$status, "error")

  document_create(state, "rmd", "Empty", text = "")
  expect_error(document_knit(state, "html"), "empty")
})

test_that("the knit history is bounded and newest first", {
  state <- report_test_state()
  for (i in 1:25) {
    document_knit_record(state, "html", status = "ok", duration_ms = i)
  }
  expect_equal(length(state$knit_history), 20L)
  expect_equal(state$knit_history[[1L]]$duration_ms, 25)
})
