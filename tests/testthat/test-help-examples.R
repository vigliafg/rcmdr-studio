test_that("examples are parsed from front matter", {
  examples <- help_parse_examples(list(
    list(code = "summary(Dataset)", runnable = TRUE, title = "Quick"),
    list(code = "str(Dataset)", runnable = FALSE)
  ))
  expect_length(examples, 2L)
  expect_true(examples[[1L]]$runnable)
  expect_false(examples[[2L]]$runnable)
  expect_equal(examples[[1L]]$title, "Quick")
})

test_that("plain strings are accepted as non-runnable examples", {
  examples <- help_parse_examples(c("summary(Dataset)", "str(Dataset)"))
  expect_length(examples, 2L)
  expect_false(examples[[1L]]$runnable)
})

test_that("invalid entries are ignored", {
  examples <- help_parse_examples(list(
    list(runnable = TRUE),
    list(code = "", runnable = TRUE),
    list(code = "summary(Dataset)")
  ))
  expect_length(examples, 1L)
  expect_equal(examples[[1L]]$code, "summary(Dataset)")
})

test_that("the shipped numerical summaries topic has a runnable example", {
  help_unregister()
  on.exit(help_unregister(), add = TRUE)
  examples <- help_topic_examples(help_topic("numerical-summaries"))
  expect_true(any(vapply(examples, function(example) example$runnable,
                         logical(1))))
  expect_true(any(vapply(examples, function(example) {
    grepl("summary(Dataset)", example$code, fixed = TRUE)
  }, logical(1))))
})

test_that("the example UI shows Run only for runnable code", {
  topic <- list(id = "demo")
  runnable <- help_example_ui(topic, list(index = 1L, code = "summary(x)",
                                          runnable = TRUE, title = NULL))
  static <- help_example_ui(topic, list(index = 2L, code = "str(x)",
                                        runnable = FALSE, title = NULL))
  expect_match(as.character(runnable), "data-help-example-index")
  expect_false(grepl("data-help-example-index", as.character(static),
                     fixed = TRUE))
  expect_match(as.character(runnable), "data-help-example-insert")
})

test_that("examples substitute the active data set name", {
  env <- new.env()
  assign("df", data.frame(y = 1:3), envir = env)
  state <- AppState(env)
  active_dataset(state, "df")

  prepared <- help_example_prepare_code(state, "summary(Dataset)")
  expect_equal(prepared$code, "summary(df)")
  expect_null(prepared$error)

  prepared <- help_example_prepare_code(state, "summary({dataset})")
  expect_equal(prepared$code, "summary(df)")
})

test_that("an example that needs data reports a clear error", {
  state <- AppState(new.env())
  prepared <- help_example_prepare_code(state, "summary(Dataset)")
  expect_match(prepared$error, "data set")
})
