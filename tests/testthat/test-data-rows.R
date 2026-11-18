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

test_that("several cells in one column become one command", {
  old <- data.frame(a = 1:5)
  new <- old
  new$a[c(2L, 4L)] <- c(20, 40)
  expect_equal(
    RcmdrShiny:::cmd_edit_cells("D", old, new),
    'D[c(2, 4), "a"] <- c(20, 40)'
  )
})

test_that("a new factor level is declared before the assignment", {
  state <- AppState(env = new.env())
  state$env$D <- data.frame(f = factor(c("a", "b", "a")))
  active_dataset(state, "D")
  new <- data.frame(f = factor(c("c", "b", "a"),
                               levels = c("a", "b", "c")))
  commands <- RcmdrShiny:::cmd_edit_cells("D", state$env$D, new)
  expect_equal(commands, c(
    'levels(D[["f"]]) <- c(levels(D[["f"]]), "c")',
    'D[1, "f"] <- "c"'
  ))
  for (command in commands) {
    expect_equal(run_command(state, command)$status, "ok")
  }
  expect_s3_class(state$env$D$f, "factor")
  expect_false(is.ordered(state$env$D$f))
  expect_equal(as.character(state$env$D$f), c("c", "b", "a"))
})

test_that("an ordered factor stays ordered", {
  old <- data.frame(f = factor(c("low", "high"), levels = c("low", "high"),
                               ordered = TRUE))
  new <- old
  new$f <- factor(c("mid", "high"), levels = c("low", "mid", "high"),
                  ordered = TRUE)
  aligned <- RcmdrShiny:::align_edited_data(old, new)
  expect_true(is.ordered(aligned$f))
  expect_equal(levels(aligned$f), c("low", "high", "mid"))
})

test_that("dates and missing values get type-preserving commands", {
  old <- data.frame(d = as.Date(c("2026-11-01", "2026-11-02")),
                    x = c(1, 2))
  new <- old
  new$d[2L] <- as.Date("2026-11-20")
  new$x[1L] <- NA_real_
  expect_equal(
    RcmdrShiny:::cmd_edit_cells("D", old, new),
    c('D[2, "d"] <- as.Date("2026-11-20")', 'D[1, "x"] <- NA')
  )
})

test_that("invalid edits are refused before a command is generated", {
  old <- data.frame(a = c(1, 2), l = c(TRUE, FALSE),
                    d = as.Date(c("2026-11-01", "2026-11-02")))
  expect_match(
    RcmdrShiny:::validate_edited_data(
      old, data.frame(a = c("1", "oops"), l = c(TRUE, FALSE), d = old$d)
    ),
    "Column a needs numeric values"
  )
  expect_match(
    RcmdrShiny:::validate_edited_data(
      old, data.frame(a = old$a, l = c("maybe", "FALSE"), d = old$d)
    ),
    "Column l needs TRUE or FALSE"
  )
  expect_match(
    RcmdrShiny:::validate_edited_data(
      old, data.frame(a = old$a, l = old$l,
                      d = c("2026-11-01", "not a date"))
    ),
    "Column d needs a valid date"
  )
  expect_match(
    RcmdrShiny:::validate_edited_data(old, old[1L, , drop = FALSE]),
    "number of rows"
  )
})

test_that("date-time and list columns are read-only in the editor", {
  df <- data.frame(
    a = 1:2,
    when = as.POSIXct(c("2026-11-18 10:00:00", "2026-11-18 11:00:00"),
                     tz = "UTC"),
    payload = I(list(list(x = 1), list(x = 2)))
  )
  expect_equal(RcmdrShiny:::editor_readonly_columns(df),
               c("when", "payload"))
  old <- df
  new <- df
  new$when <- as.POSIXct(c("2026-11-19 10:00:00", "2026-11-18 11:00:00"),
                         tz = "UTC")
  expect_match(
    RcmdrShiny:::validate_edited_data(old, new),
    "Column when is read-only"
  )
})

test_that("a stale editor cannot be applied", {
  context <- list(dataset = "D", token = "ed-1")
  expect_match(
    RcmdrShiny:::editor_apply_error("view", context, "ed-1", "ed-1", "D"),
    "only available in Edit mode"
  )
  expect_match(
    RcmdrShiny:::editor_apply_error("edit", context, "ed-1", "ed-1", "Other"),
    "another data set"
  )
  expect_match(
    RcmdrShiny:::editor_apply_error("edit", context, "ed-old", "ed-new", "D"),
    "data changed since the editor opened"
  )
  expect_null(
    RcmdrShiny:::editor_apply_error("edit", context, "ed-1", "ed-1", "D")
  )
})
