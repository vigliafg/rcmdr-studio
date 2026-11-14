test_that("variable metadata describes type, missing and levels", {
  env <- new.env()
  env$Dataset <- data.frame(
    x = c(1, 2, NA, 4),
    g = factor(c("a", "a", "b", "b")),
    s = c("u", "v", "u", "v"),
    b = c(TRUE, FALSE, TRUE, FALSE),
    d = as.Date("2026-01-01") + 0:3
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")

  expect_equal(variable_info(state, "x")$type, "numeric")
  expect_equal(variable_info(state, "x")$missing, 1L)
  expect_equal(variable_info(state, "g")$type, "factor")
  expect_equal(variable_info(state, "g")$levels, c("a", "b"))
  expect_equal(variable_info(state, "s")$type, "character")
  expect_equal(variable_info(state, "b")$type, "logical")
  expect_equal(variable_info(state, "d")$type, "date")
  expect_null(variable_info(state, "missing"))
})

suggestions_test_state <- function() {
  env <- new.env(parent = globalenv())
  env$Dataset <- data.frame(
    x = c(1, 2, 3, 4, 5, 6),
    y = c(2, 4, 6, 8, 10, 12),
    g = factor(c("a", "a", "b", "b", "c", "c"))
  )
  state <- AppState(env = env)
  active_dataset(state, "Dataset")
  state
}

test_that("numeric and factor variables get type-specific suggestions", {
  state <- suggestions_test_state()

  numeric <- variable_suggestions(state, "x")
  expect_true(all(c("summary", "histogram", "density", "boxplot", "scatter",
                    "correlation") %in% numeric$id))
  expect_true(all(numeric$available))

  factor <- variable_suggestions(state, "g")
  expect_true(all(c("frequency", "bar", "boxplot", "twoway", "recode") %in%
                    factor$id))
  expect_false(factor$available[factor$id == "twoway"])

  expect_equal(nrow(variable_suggestions(state, "missing")), 0L)
})

test_that("suggestions pre-fill the existing dialogs", {
  state <- suggestions_test_state()

  expect_equal(suggestion_memory(state, "x", "numericalSummaries")$x, "x")
  expect_equal(suggestion_memory(state, "x", "Histogram")$variable, "x")
  expect_equal(suggestion_memory(state, "x", "boxPlot")$variables, "x")
  expect_equal(suggestion_memory(state, "g", "frequencyDistribution")$variables,
               "g")
  expect_equal(suggestion_memory(state, "g", "twoWayTable")$row, "g")
})

test_that("descriptions include type, missing values and unique values", {
  state <- suggestions_test_state()
  descriptions <- variable_descriptions(state)
  expect_setequal(names(descriptions), c("x", "y", "g"))
  expect_match(descriptions[["x"]], "numeric")
  expect_match(descriptions[["x"]], "0 missing")
  expect_match(descriptions[["g"]], "factor")
})

test_that("the suggestion UI emits the variable and dialog", {
  state <- suggestions_test_state()
  html <- as.character(variable_suggestions_ui(state, "g"))
  expect_match(html, "rcmdr-variable-suggestions")
  expect_match(html, "variable_suggestion")
  expect_match(html, "frequencyDistribution")
  expect_match(html, "Boxplot by group")
  expect_null(variable_suggestions_ui(state, "missing"))
})
