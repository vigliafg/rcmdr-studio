test_that("row builders add, duplicate and delete rows", {
  env <- new.env()
  env$D <- data.frame(a = 1:4, b = letters[1:4], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")

  expect_equal(
    RcmdrShiny:::cmd_add_row("D"),
    "D[nrow(D) + 1L, ] <- NA"
  )
  expect_equal(run_command(state, RcmdrShiny:::cmd_add_row("D"))$status, "ok")
  expect_equal(nrow(env$D), 5L)
  expect_true(is.na(env$D$a[[5L]]))

  expect_equal(
    RcmdrShiny:::cmd_add_row("D", c(a = "9", b = '"z"')),
    'D[nrow(D) + 1L, c("a", "b")] <- list(9, "z")'
  )
  expect_equal(
    run_command(state, RcmdrShiny:::cmd_add_row("D", c(a = "9", b = '"z"')))$status,
    "ok"
  )
  expect_equal(env$D$a[[6L]], 9)
  expect_equal(env$D$b[[6L]], "z")

  expect_equal(
    RcmdrShiny:::cmd_duplicate_rows("D", c(1, 2)),
    "D <- rbind(D, D[c(1, 2), , drop = FALSE])"
  )
  expect_equal(
    run_command(state, RcmdrShiny:::cmd_duplicate_rows("D", c(1, 2)))$status,
    "ok"
  )
  expect_equal(nrow(env$D), 8L)

  expect_equal(
    RcmdrShiny:::cmd_delete_rows("D", c(1, 8)),
    "D <- D[-c(1, 8), , drop = FALSE]"
  )
  expect_equal(
    run_command(state, RcmdrShiny:::cmd_delete_rows("D", c(1, 8)))$status,
    "ok"
  )
  expect_equal(nrow(env$D), 6L)
})

test_that("row builders reject empty selections", {
  expect_equal(RcmdrShiny:::cmd_delete_rows("D", integer()), character())
  expect_equal(RcmdrShiny:::cmd_duplicate_rows("D", integer()), character())
  expect_error(RcmdrShiny:::cmd_add_row("D", c("9")), "named")
})

test_that("selected rows become a reproducible subset command", {
  env <- new.env()
  env$D <- data.frame(a = 1:5, b = letters[1:5], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_data_selection(state, rows = c(1L, 3L), columns = c("a", "b"))
  expect_equal(selection_summary(state), "2 row(s) - 2 column(s)")
  expect_equal(selection_expression(state), "c(1, 3)")
  expect_equal(
    selection_subset_command(state, "Sub"),
    'Sub <- D[c(1, 3), c("a", "b"), drop = FALSE]'
  )

  expect_equal(run_command(state, selection_subset_command(state, "Sub"))$status,
               "ok")
  expect_equal(nrow(state$env$Sub), 2L)
  expect_equal(names(state$env$Sub), c("a", "b"))

  clear_data_selection(state)
  expect_equal(selection_summary(state), "No selection")
  expect_null(selection_subset_command(state, "Sub2"))
})

test_that("filter expressions are used as subset conditions", {
  env <- new.env()
  env$D <- data.frame(a = 1:5, b = letters[1:5], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_data_selection(state, expression = "a > 2", columns = "b")
  expect_equal(
    selection_subset_command(state, "Filtered"),
    "Filtered <- subset(D, subset=a > 2, select=c(b))"
  )
})

test_that("cell edits are translated into reproducible commands", {
  env <- new.env()
  env$D <- data.frame(
    a = c(1, 2, 3),
    b = c("x", "y", "z"),
    l = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")

  edited <- env$D
  edited$a[[2L]] <- 20
  edited$b[[1L]] <- "new"
  edited$l[[3L]] <- FALSE
  commands <- RcmdrShiny:::cmd_edit_cells("D", env$D, edited)
  expect_equal(commands, c(
    'D[2, "a"] <- 20',
    'D[1, "b"] <- "new"',
    'D[3, "l"] <- FALSE'
  ))

  for (command in commands) {
    expect_equal(run_command(state, command)$status, "ok")
  }
  expect_equal(env$D$a, c(1, 20, 3))
  expect_equal(env$D$b, c("new", "y", "z"))
  expect_equal(env$D$l, c(TRUE, FALSE, FALSE))

  expect_equal(RcmdrShiny:::cmd_edit_cells("D", env$D, env$D), character())
})
