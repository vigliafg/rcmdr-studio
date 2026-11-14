# Console helpers ------------------------------------------------------------

test_that("the console history is bounded and recall walks it", {
  state <- workbench_test_state()
  console_history_add(state, "summary(D)")
  console_history_add(state, "mean(D$y)")
  expect_equal(length(state$console_history), 2L)
  expect_equal(console_history_recall(state, -1L), "mean(D$y)")
  expect_equal(console_history_recall(state, -1L), "summary(D)")
  expect_equal(console_history_recall(state, -1L), "summary(D)")
  expect_equal(console_history_recall(state, 1L), "mean(D$y)")
  expect_equal(console_history_recall(state, 1L), "")
})

test_that("the console history respects its option", {
  state <- workbench_test_state()
  state$options$console_history_length <- 3L
  for (i in 1:6) console_history_add(state, sprintf("x <- %d", i))
  expect_equal(length(state$console_history), 3L)
  expect_equal(state$console_history, c("x <- 4", "x <- 5", "x <- 6"))
})

test_that("console commands share log, history and output", {
  state <- workbench_test_state()
  result <- console_execute(state, "mean(D$y)")
  expect_equal(result$status, "ok")
  expect_equal(tail(state$log, 1L), "mean(D$y)")
  expect_equal(state$history[[1L]]$source, "console")
  expect_equal(state$console_last$status, "ok")
  expect_equal(length(state$console_history), 1L)
  expect_true(any(grepl("\\[1\\] 5", result$output)))
})

test_that("interactive commands are blocked before evaluation", {
  state <- workbench_test_state()
  result <- console_execute(state, "readline('name? ')")
  expect_equal(result$status, "blocked")
  expect_equal(length(state$history), 0L)
  expect_equal(length(state$console_history), 0L)
  expect_true(console_is_interactive("menu(c('a', 'b'))"))
  expect_true(console_is_interactive("file.choose()"))
  expect_false(console_is_interactive("summary(D)"))
})

test_that("console entries can be searched and filtered", {
  state <- workbench_test_state()
  console_execute(state, "summary(D)")
  console_execute(state, "stop('boom')")
  expect_equal(length(console_entries(state)), 2L)
  expect_equal(length(console_entries(state, "summary")), 1L)
  expect_equal(length(console_entries(state, "", "ok")), 1L)
  expect_equal(length(console_entries(state, "", "error")), 1L)
})

test_that("the console UI exposes input, history and filters", {
  html <- htmltools::renderTags(console_studio_ui())$html
  expect_match(html, "console_input")
  expect_match(html, "console_run")
  expect_match(html, "console_prev")
  expect_match(html, "console_next")
  expect_match(html, "console_filter")
  expect_match(html, "console_status")
  expect_match(html, "console_log")
})
