# Contextual insertion -------------------------------------------------------

test_that("text and sections are inserted without losing chunks", {
  state <- report_test_state()
  report_sample_document(state)
  before <- nrow(document_chunks(document_text(state), "rmd"))
  report_insert_text(state, "A new paragraph.")
  report_insert_text(state, "New section", level = 2)
  expect_match(document_text(state), "A new paragraph\\.")
  expect_match(document_text(state), "(?m)^## New section$", perl = TRUE)
  expect_equal(nrow(document_chunks(document_text(state), "rmd")), before)
})

test_that("a chunk is inserted with a label", {
  state <- report_test_state()
  report_sample_document(state)
  report_insert_chunk(state, "table(D$g)", label = "counts")
  expect_match(document_text(state), "```\\{r counts\\}")
  expect_match(document_text(state), "table\\(D\\$g\\)")
})

test_that("history output is inserted as a literal block", {
  state <- report_test_state()
  report_sample_document(state)
  run_command(state, "summary(D$y)")
  entry <- state$history[[length(state$history)]]
  report_insert_output(state, entry$id)
  expect_match(document_text(state), "### Output")
  expect_match(document_text(state), "Min")
})

test_that("inserting output without history fails clearly", {
  state <- report_test_state()
  report_sample_document(state)
  expect_error(report_insert_output(state), "no command output")
})

test_that("a plot is copied next to the report and included", {
  state <- report_test_state()
  report_sample_document(state)
  report_fake_plot(state, "Inserted")
  target <- report_insert_plot(state, key = NULL, caption = "My plot")
  expect_true(file.exists(target))
  expect_match(target, state$report_dir, fixed = TRUE)
  expect_match(document_text(state), "knitr::include_graphics")
  expect_match(document_text(state), "\\*My plot\\*")
})

test_that("tables and profiles are inserted", {
  state <- report_test_state()
  report_sample_document(state)
  report_insert_table(state, state$env$D, caption = "Table 1")
  expect_match(document_text(state), "Table 1")
  expect_match(document_text(state), "\\|")

  report_insert_data_profile(state, "D")
  expect_match(document_text(state), "## Data profile")
  expect_match(document_text(state), "colSums\\(is\\.na\\(D\\)\\)")
})

test_that("a model summary is inserted for the active model", {
  state <- report_test_state()
  report_sample_document(state)
  state$env$fit <- lm(y ~ x, data = state$env$D)
  state$active_model <- "fit"
  report_insert_model_summary(state)
  expect_match(document_text(state), "## Model `fit`")
  expect_match(document_text(state), "summary\\(fit\\)")
})

test_that("a history step becomes a reproducible chunk", {
  state <- report_test_state()
  report_sample_document(state)
  run_command(state, "mean(D$y)")
  entry <- state$history[[length(state$history)]]
  report_insert_history_step(state, entry$id)
  expect_match(document_text(state), "```\\{r history\\}")
  expect_match(document_text(state), "mean\\(D\\$y\\)")
})

test_that("insertion before the end of an Rnw document stays inside", {
  state <- report_test_state()
  document_create(
    state, "rnw", "Latex",
    text = c("\\documentclass{article}", "\\begin{document}", "",
             "Text", "", "\\end{document}")
  )
  report_insert_text(state, "Inserted paragraph.")
  text <- document_text(state)
  expect_true(regexpr("Inserted paragraph", text) <
                regexpr("\\\\end\\{document\\}", text))
})
