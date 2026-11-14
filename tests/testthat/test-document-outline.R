# Document outline and chunks ------------------------------------------------

test_that("the outline lists headings outside chunks", {
  state <- report_test_state()
  report_sample_document(state)
  text <- document_text(state)
  outline <- document_outline(text, "rmd")
  expect_equal(nrow(outline), 2L)
  expect_equal(outline$title, c("Context", "Results"))
  expect_equal(outline$level, c(2L, 2L))
  expect_true(outline$line[[1L]] < outline$line[[2L]])
})

test_that("levels and trailing hashes are normalised", {
  text <- paste(
    "# One", "### Three", "## Two ##", "", sep = "\n"
  )
  outline <- document_outline(text, "rmd")
  expect_equal(outline$level, c(1L, 3L, 2L))
  expect_equal(outline$title, c("One", "Three", "Two"))
})

test_that("headings inside chunks are ignored", {
  text <- paste(
    "## Real", "", "```{r}", "## fake", "```", "", "### Also real", "",
    sep = "\n"
  )
  outline <- document_outline(text, "rmd")
  expect_equal(outline$title, c("Real", "Also real"))
})

test_that("chunks carry stable ids, labels and code", {
  state <- report_test_state()
  report_sample_document(state)
  chunks <- document_chunks(document_text(state), "rmd")
  expect_equal(nrow(chunks), 2L)
  expect_equal(chunks$label, c("summary", "second"))
  expect_equal(chunks$id, c("chunk-summary", "chunk-second"))
  expect_match(chunks$code[[1L]], "summary\\(D\\)")
  expect_match(chunks$code[[2L]], "mean\\(D\\$y\\)")
  expect_equal(chunks$start[[1L]] + 1L, chunks$end[[1L]] - 1L)
})

test_that("duplicate labels get unique ids", {
  text <- paste(
    "```{r same}", "1", "```", "", "```{r same}", "2", "```", "",
    sep = "\n"
  )
  chunks <- document_chunks(text, "rmd")
  expect_equal(length(unique(chunks$id)), 2L)
})

test_that("chunks can be found by id", {
  state <- report_test_state()
  report_sample_document(state)
  chunk <- document_chunk_by_id(document_text(state), "chunk-second", "rmd")
  expect_equal(chunk$code[[1L]], "mean(D$y)")
  expect_null(document_chunk_by_id(document_text(state), "missing", "rmd"))
})

test_that("knitr chunks and sections are parsed", {
  text <- paste(
    "\\section{One}", "", "<<setup, echo=FALSE>>=", "x <- 1", "@", "",
    "\\subsection{Two}", "",
    sep = "\n"
  )
  outline <- document_outline(text, "rnw")
  expect_equal(outline$title, c("One", "Two"))
  expect_equal(outline$level, c(1L, 2L))

  chunks <- document_chunks(text, "rnw")
  expect_equal(nrow(chunks), 1L)
  expect_equal(chunks$label[[1L]], "setup")
  expect_equal(chunks$code[[1L]], "x <- 1")
})

test_that("plain R mode has no outline or chunks", {
  expect_equal(nrow(document_outline("x <- 1", "r")), 0L)
  expect_equal(nrow(document_chunks("x <- 1", "r")), 0L)
})
