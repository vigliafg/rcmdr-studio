test_that("field errors are normalised from lists and vectors", {
  expect_equal(
    dialog_field_errors(list(field_errors = c(x = "Pick a variable"))),
    list(x = "Pick a variable")
  )
  expect_equal(
    dialog_field_errors(list(field_errors = list(
      x = c("Pick", "a variable"), groups = NULL, runtime = ""
    ))),
    list(x = "Pick a variable")
  )
  expect_length(dialog_field_errors(list()), 0L)
  expect_length(dialog_field_errors(list(field_errors = 1)), 0L)
})

test_that("the validation summary renders links to the fields", {
  html <- as.character(dialog_validation_ui(list(
    numericalSummaries_x = "Pick a variable",
    numericalSummaries_groups = "Pick a group"
  )))
  expect_match(html, "rcmdr-dialog-errors")
  expect_match(html, "aria-live")
  expect_match(html, "rcmdrFocusField")
  expect_match(html, "numericalSummaries_x")
  expect_match(html, "Pick a group")
  expect_null(dialog_validation_ui(list()))
})

test_that("the browser payload keeps the field identifiers", {
  payload <- dialog_validation_payload(list(x = "Pick a variable"))
  expect_equal(payload$errors$x, "Pick a variable")
})
