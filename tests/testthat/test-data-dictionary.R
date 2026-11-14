test_that("labels and units are stored on the data frame", {
  env <- new.env()
  env$D <- data.frame(length = 1:3, species = factor(c("a", "b", "a")))
  state <- AppState(env = env)
  active_dataset(state, "D")

  set_variable_label(
    state, "D", "length",
    label = "Sepal length", units = "cm", description = "Measured in cm"
  )

  meta <- variable_label(state, "D", "length")
  expect_equal(meta$label, "Sepal length")
  expect_equal(meta$units, "cm")
  expect_equal(meta$description, "Measured in cm")
  expect_equal(attr(env$D$length, "label", exact = TRUE), "Sepal length")
  expect_equal(attr(env$D$length, "units", exact = TRUE), "cm")
  expect_false(identical(env$D$length, 1:3))
})

test_that("the dictionary table joins attributes and registry metadata", {
  env <- new.env()
  env$D <- data.frame(
    length = 1:3, species = factor(c("a", "b", "a")), note = c("x", NA, "y"),
    stringsAsFactors = FALSE
  )
  state <- AppState(env = env)
  active_dataset(state, "D")
  set_variable_label(state, "D", "length", label = "Length", units = "cm")
  set_variable_label(state, "D", "species", label = "Species")

  table <- dictionary_table(state, "D")
  expect_equal(table$variable, c("length", "species", "note"))
  expect_equal(table$label[1:2], c("Length", "Species"))
  expect_equal(table$missing[[3L]], 1L)
  expect_equal(table$class[[2L]], "factor")
})

test_that("the dictionary command reproduces the attribute assignment", {
  expect_equal(
    RcmdrShiny:::cmd_set_variable_label(
      "D", "x", label = "Length", units = "cm", description = "A measure"
    ),
    c(
      'attr(D$x, "label") <- "Length"',
      'attr(D$x, "units") <- "cm"',
      'attr(D$x, "description") <- "A measure"'
    )
  )

  env <- new.env()
  env$D <- data.frame(x = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "D")
  result <- run_command(
    state,
    RcmdrShiny:::cmd_set_variable_label("D", "x", label = "Length")
  )
  expect_equal(result$status, "ok")
  expect_equal(attr(env$D$x, "label", exact = TRUE), "Length")
})

test_that("the dictionary exports a stable table", {
  env <- new.env()
  env$D <- data.frame(x = 1:3)
  state <- AppState(env = env)
  active_dataset(state, "D")
  set_variable_label(state, "D", "x", label = "X", units = "kg")

  export <- dictionary_export(state, "D")
  expect_equal(names(export), c("variable", "class", "label", "units",
                                "description", "missing"))
  expect_equal(export$label, "X")
  expect_equal(export$units, "kg")
})
