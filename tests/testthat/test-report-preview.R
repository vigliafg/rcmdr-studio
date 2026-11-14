# Report preview -------------------------------------------------------------

test_that("the Markdown preview renders headings and chunk placeholders", {
  state <- report_test_state()
  report_sample_document(state)
  preview <- report_preview(document_text(state), "rmd")
  html <- as.character(preview$html)
  expect_match(html, "<h1>Test report</h1>")
  expect_match(html, "<h2>Context</h2>")
  expect_match(html, "rcmdr-report-chunk")
  expect_match(html, "Chunk: summary")
  expect_match(html, "summary\\(D\\)")
})

test_that("the fast preview never executes code", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Safe",
    text = c("## Safe", "", "```{r}", "stop(\"boom\")", "```")
  )
  log_before <- state$log
  output_before <- state$output
  preview <- report_preview(document_text(state), "rmd")
  expect_match(as.character(preview$html), "stop")
  expect_equal(state$log, log_before)
  expect_equal(state$output, output_before)
})

test_that("the front matter is shown as a title block", {
  state <- report_test_state()
  document_create(
    state, "rmd", "Titled",
    text = c("---", 'title: "A title"', 'author: "Ada"',
             'date: "2026-01-02"', "---", "", "Body")
  )
  html <- as.character(report_preview(document_text(state), "rmd")$html)
  expect_match(html, "<h1>A title</h1>")
  expect_match(html, "Ada")
  expect_match(html, "2026-01-02")
})

test_that("previews are cached by mode and text", {
  state <- report_test_state()
  report_sample_document(state)
  report_preview_clear()
  first <- report_preview(document_text(state), "rmd")
  second <- report_preview(document_text(state), "rmd")
  expect_identical(first$html, second$html)
  expect_equal(length(.report_preview_cache$entries), 1L)

  changed <- paste(document_text(state), "\n\nMore text")
  report_preview(changed, "rmd")
  expect_equal(length(.report_preview_cache$entries), 2L)
})

test_that("Rnw and R documents fall back to a source preview", {
  state <- report_test_state()
  document_create(state, "rnw", "Latex", text = "\\section{One}")
  preview <- report_preview(document_text(state), "rnw")
  expect_match(as.character(preview$html), "previewed after knitting")

  document_create(state, "r", "Script", text = "x <- 1")
  preview <- report_preview(document_text(state), "r")
  expect_match(as.character(preview$html), "x &lt;- 1")
})

test_that("the preview exposes outline and chunks", {
  state <- report_test_state()
  report_sample_document(state)
  preview <- report_preview(document_text(state), "rmd")
  expect_equal(nrow(preview$outline), 2L)
  expect_equal(nrow(preview$chunks), 2L)
})
