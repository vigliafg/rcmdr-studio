# Output cards, filters and structured messages ------------------------------

test_that("history filters combine query, source and status", {
  state <- workbench_test_state()
  run_command(state, "summary(D)", source = "dialog")
  run_command(state, "mean(D$y)", source = "console")
  run_command(state, "stop('boom')", source = "console")

  expect_equal(length(history_filter_entries(state$history)), 3L)
  expect_equal(length(history_filter_entries(state$history, "", "console")), 2L)
  expect_equal(length(history_filter_entries(state$history, "", "all", "ok")), 2L)
  expect_equal(length(history_filter_entries(state$history, "", "console", "error")), 1L)
  expect_equal(length(history_filter_entries(state$history, "mean(D$y)")), 1L)
  expect_equal(length(history_filter_entries(state$history, "min.")), 1L)
})

test_that("cards can be pinned and unpinned", {
  state <- workbench_test_state()
  run_command(state, "summary(D)")
  id <- state$history[[1L]]$id
  expect_true(history_toggle_pin(state, id))
  expect_equal(history_pinned_ids(state), id)
  expect_false(history_toggle_pin(state, id))
  expect_equal(length(history_pinned_ids(state)), 0L)
})

test_that("the card shows output, actions and the pinned state", {
  state <- workbench_test_state()
  run_command(state, "summary(D)", source = "console")
  entry <- state$history[[1L]]
  html <- htmltools::renderTags(history_card_ui(entry))$html
  expect_match(html, "history-action")
  expect_match(html, "Rerun")
  expect_match(html, "Pin")
  expect_match(html, "Min\\.")

  pinned <- htmltools::renderTags(history_card_ui(entry, pinned = TRUE))$html
  expect_match(pinned, "pinned")
  expect_match(pinned, "Unpin")
})

test_that("structured warnings and errors are recorded", {
  state <- workbench_test_state()
  run_command(state, "warning('careful')")
  run_command(state, "stop('boom')")
  table <- messages_as_data_frame(state)
  expect_equal(nrow(table), 2L)
  expect_equal(sort(table$severity), c("error", "warning"))
  expect_true(any(grepl("careful", table$text)))
  expect_true(any(nzchar(table$command)))

  filtered <- messages_filter(state$message_entries, "", "error")
  expect_equal(length(filtered), 1L)
  expect_match(filtered[[1L]]$text, "boom")
})

test_that("messages can be filtered and cleared", {
  state <- workbench_test_state()
  run_command(state, "warning('careful')")
  expect_equal(length(messages_filter(state$message_entries, "careful")), 1L)
  expect_equal(length(messages_filter(state$message_entries, "missing")), 0L)
  messages_clear(state)
  expect_equal(length(state$message_entries), 0L)
  expect_equal(state$message_counter, 0L)
})

test_that("message entries point back to the history step", {
  state <- workbench_test_state()
  run_command(state, "warning('careful')")
  entry <- state$history[[1L]]
  message <- state$message_entries[[1L]]
  expect_equal(message$history_id, entry$id)
})

test_that("the Output UI keeps the raw text output for compatibility", {
  html <- htmltools::renderTags(output_studio_ui())$html
  expect_match(html, "output_cards")
  expect_match(html, "output_filter")
  expect_match(html, "output_status")
  expect_match(html, "output_source")
  expect_match(html, "output_text")
})

test_that("the Messages UI offers severity filters", {
  html <- htmltools::renderTags(messages_studio_ui())$html
  expect_match(html, "messages_cards")
  expect_match(html, "messages_filter")
  expect_match(html, "messages_severity")
  expect_match(html, "messages_text")
})
