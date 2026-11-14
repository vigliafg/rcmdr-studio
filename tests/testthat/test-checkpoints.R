test_that("checkpoints snapshot and restore a data set", {
  env <- new.env()
  env$D <- data.frame(a = 1:4, b = letters[1:4], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")

  checkpoint <- checkpoint_create(state, "Before edit")
  expect_match(checkpoint$id, "^ckpt-")
  expect_equal(checkpoint$dataset, "D")
  expect_equal(checkpoint$rows, 4L)

  table <- checkpoint_list(state, "D")
  expect_equal(nrow(table), 1L)
  expect_equal(table$label, "Before edit")

  run_command(state, RcmdrShiny:::cmd_delete_rows("D", c(1, 2)))
  expect_equal(nrow(env$D), 2L)

  expect_true(checkpoint_restore(state, checkpoint$id))
  expect_equal(nrow(env$D), 4L)
  expect_equal(active_dataset(state), "D")
  expect_true(any(vapply(state$history, function(entry) {
    identical(entry$source, "checkpoint")
  }, logical(1))))
})

test_that("checkpoint lists are capped by count and memory", {
  env <- new.env()
  env$D <- data.frame(a = 1:10)
  state <- AppState(env = env)
  active_dataset(state, "D")
  state$options$checkpoint_max <- 2L

  checkpoint_create(state, "one")
  checkpoint_create(state, "two")
  checkpoint_create(state, "three")
  table <- checkpoint_list(state)
  expect_equal(nrow(table), 2L)
  expect_equal(table$label, c("three", "two"))

  state$options$checkpoint_max_bytes <- 1
  expect_null(checkpoint_create(state, "too large"))
  expect_false(is.null(state$last_checkpoint_skip))
  expect_match(state$last_checkpoint_skip$reason, "memory cap")
})

test_that("checkpoints can be cleared individually or all at once", {
  env <- new.env()
  env$D <- data.frame(a = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "D")

  first <- checkpoint_create(state, "first")
  second <- checkpoint_create(state, "second")
  expect_equal(nrow(checkpoint_list(state)), 2L)

  checkpoint_clear(state, first$id)
  expect_equal(checkpoint_list(state)$id, second$id)

  checkpoint_clear(state)
  expect_equal(nrow(checkpoint_list(state)), 0L)
  expect_false(checkpoint_restore(state, "missing"))
})
