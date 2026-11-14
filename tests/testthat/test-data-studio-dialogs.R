test_that("the Data Studio dialogs render and generate commands", {
  env <- new.env()
  env$D <- data.frame(
    a = 1:5, b = letters[1:5],
    f = factor(c("x", "y", "x", "y", "x")),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")
  set_data_selection(state, rows = c(1L, 3L), columns = "a")

  ids <- names(RcmdrShiny:::data_studio_dialogs())
  expect_true(all(c(
    "dataAddColumn", "dataDuplicateColumn", "dataColumnType",
    "dataCreateSubset", "dataDeleteRows", "dataCheckpoints",
    "dataDictionary"
  ) %in% ids))

  for (id in ids) {
    spec <- get_dialog_spec(id)
    expect_false(is.null(spec))
    html <- htmltools::renderTags(spec$ui(state, NULL))$html
    expect_gt(nchar(html), 20)
  }

  add <- get_dialog_spec("dataAddColumn")
  result <- add$on_ok(list(
    dataAddColumn_name = "ratio",
    dataAddColumn_expression = "a * 2"
  ), state)
  expect_equal(result$commands, "D$ratio <- with(D, a * 2)")

  duplicate <- get_dialog_spec("dataDuplicateColumn")
  result <- duplicate$on_ok(list(
    dataDuplicateColumn_variable = "a",
    dataDuplicateColumn_name = "a2"
  ), state)
  expect_equal(result$commands, "D$a2 <- D$a")

  type <- get_dialog_spec("dataColumnType")
  result <- type$on_ok(list(
    dataColumnType_variable = "f",
    dataColumnType_type = "character"
  ), state)
  expect_equal(result$commands, "D$f <- as.character(D$f)")

  subset <- get_dialog_spec("dataCreateSubset")
  result <- subset$on_ok(list(dataCreateSubset_name = "Sub"), state)
  expect_match(result$commands, "Sub <- D\\[c\\(1, 3\\)")
})

test_that("Data Studio dialogs validate their inputs", {
  env <- new.env()
  env$D <- data.frame(a = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "D")

  add <- get_dialog_spec("dataAddColumn")
  expect_match(add$on_ok(list(dataAddColumn_name = "1 bad"), state)$error,
               "valid column name")
  expect_match(add$on_ok(list(dataAddColumn_name = "a"), state)$error,
               "already exists")

  duplicate <- get_dialog_spec("dataDuplicateColumn")
  expect_match(
    duplicate$on_ok(list(dataDuplicateColumn_variable = "a",
                         dataDuplicateColumn_name = "a"), state)$error,
    "new, valid"
  )

  subset <- get_dialog_spec("dataCreateSubset")
  expect_match(subset$on_ok(list(dataCreateSubset_name = "Sub"), state)$error,
               "Select rows")
})

test_that("the delete-rows dialog creates a checkpoint and a command", {
  env <- new.env()
  env$D <- data.frame(a = 1:5, b = letters[1:5], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")
  set_data_selection(state, rows = c(1L, 2L))

  spec <- get_dialog_spec("dataDeleteRows")
  result <- spec$on_ok(list(), state)
  expect_match(result$commands, "D <- D\\[-c\\(1, 2\\)")
  expect_equal(nrow(checkpoint_list(state)), 1L)

  expect_equal(
    run_command(state, result$commands)$status,
    "ok"
  )
  expect_equal(nrow(state$env$D), 3L)
  expect_true(checkpoint_restore(state, checkpoint_list(state)$id[[1L]]))
  expect_equal(nrow(state$env$D), 5L)
})

test_that("the dictionary dialog updates labels and returns the command", {
  env <- new.env()
  env$D <- data.frame(a = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "D")

  spec <- get_dialog_spec("dataDictionary")
  result <- spec$on_ok(list(
    dataDictionary_variable = "a",
    dataDictionary_label = "Alpha",
    dataDictionary_units = "cm",
    dataDictionary_description = "Measured"
  ), state)

  expect_match(result$commands[[1L]], 'attr\\(D\\$a, "label"\\) <- "Alpha"')
  expect_equal(variable_label(state, "D", "a")$label, "Alpha")
  expect_equal(attr(env$D$a, "label", exact = TRUE), "Alpha")
})

test_that("the checkpoints dialog restores the selected snapshot", {
  env <- new.env()
  env$D <- data.frame(a = 1:3, b = letters[1:3], stringsAsFactors = FALSE)
  state <- AppState(env = env)
  active_dataset(state, "D")
  checkpoint <- checkpoint_create(state, "Before change")
  run_command(state, "D <- D[1:2, , drop = FALSE]")
  expect_equal(nrow(state$env$D), 2L)

  spec <- get_dialog_spec("dataCheckpoints")
  expect_false(isTRUE(spec$preview))
  result <- spec$on_ok(list(dataCheckpoints_checkpoint = checkpoint$id), state)
  expect_true(is.null(result$error))
  expect_equal(nrow(state$env$D), 3L)
})
