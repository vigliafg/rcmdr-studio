test_that("the data set registry follows the evaluation environment", {
  env <- new.env()
  state <- AppState(env = env)

  expect_equal(nrow(dataset_registry(state)), 0L)

  env$First <- data.frame(a = 1:3, b = letters[1:3])
  env$Second <- data.frame(x = 1:2, y = c(TRUE, FALSE))

  registry <- dataset_registry(state)
  expect_equal(sort(registry$name), c("First", "Second"))
  expect_equal(registry$rows[registry$name == "First"], 3L)
  expect_equal(registry$cols[registry$name == "Second"], 2L)
  expect_match(registry$classes[registry$name == "First"], "a:integer")
  expect_false(any(registry$active))

  expect_equal(dataset_activate(state, "Second"), "Second")
  expect_equal(active_dataset(state), "Second")
  expect_true(dataset_registry(state)$active[dataset_registry(state)$name == "Second"])

  env$Second <- NULL
  expect_false("Second" %in% dataset_registry(state)$name)
})

test_that("metadata and source labels survive registry refreshes", {
  env <- new.env()
  env$D <- data.frame(x = 1:3)
  state <- AppState(env = env)

  meta <- dataset_register(state, "D", source = "csv:/tmp/D.csv")
  expect_equal(meta$name, "D")
  expect_equal(meta$source, "csv:/tmp/D.csv")
  expect_equal(dataset_metadata(state, "D")$source, "csv:/tmp/D.csv")

  env$D$y <- 4:6
  dataset_register(state, "D", refresh = TRUE)
  expect_equal(dataset_metadata(state, "D")$cols, 2L)
  expect_equal(dataset_metadata(state, "D")$source, "csv:/tmp/D.csv")

  expect_true(dataset_unregister(state, "D"))
  expect_false("D" %in% names(state$datasets))
  expect_true(exists("D", envir = env, inherits = FALSE))
})

test_that("data frames assigned by a command enter the registry", {
  env <- new.env()
  state <- AppState(env = env)

  run_command(state, "Derived <- data.frame(a = 1:4)")
  expect_equal(active_dataset(state), "Derived")
  registry <- dataset_registry(state)
  expect_true("Derived" %in% registry$name)
  expect_equal(registry$source[registry$name == "Derived"], "command")
  expect_equal(registry$rows[registry$name == "Derived"], 4L)
})

test_that("data set labels include dimensions", {
  env <- new.env()
  env$D <- data.frame(x = 1:4, y = 5:8)
  state <- AppState(env = env)
  active_dataset(state, "D")
  expect_equal(dataset_label(state, "D"), "D (4 x 2)")
  expect_equal(unname(dataset_choices(state)), "D")
})
