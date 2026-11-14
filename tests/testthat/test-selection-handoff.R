test_that("selection is scoped to the active data set", {
  env <- new.env()
  env$D <- data.frame(a = 1:4, b = letters[1:4], stringsAsFactors = FALSE)
  env$E <- data.frame(x = 5:8)
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_data_selection(state, rows = c(2L, 4L), columns = "a")
  expect_equal(data_selection(state)$dataset, "D")
  expect_equal(data_selection(state)$rows, c(2L, 4L))

  active_dataset(state, "E")
  selection <- data_selection(state)
  expect_equal(selection$dataset, "E")
  expect_equal(selection$rows, integer())
  expect_equal(selection$columns, character())
})

test_that("selection accepts expressions and clears cleanly", {
  env <- new.env()
  env$D <- data.frame(a = 1:4)
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_data_selection(state, expression = "a >= 3")
  expect_equal(selection_summary(state), "filter: a >= 3")
  expect_equal(selection_expression(state), "a >= 3")

  clear_data_selection(state)
  expect_equal(selection_summary(state), "No selection")
  expect_equal(selection_expression(state), "")
})

test_that("subset commands are never produced without a selection", {
  env <- new.env()
  env$D <- data.frame(a = 1:4)
  state <- AppState(env = env)
  active_dataset(state, "D")
  expect_null(selection_subset_command(state, "Sub"))
})

test_that("selection columns are validated against the data set", {
  env <- new.env()
  env$D <- data.frame(a = 1:4, b = 5:8)
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_data_selection(state, rows = 1L, columns = c("a", "missing"))
  expect_equal(data_selection(state)$columns, "a")
})
