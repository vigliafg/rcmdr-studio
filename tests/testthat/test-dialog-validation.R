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

test_that("the Options dialog is five accordion panels with every id", {
  spec <- get_dialog_spec("Options")
  html <- htmltools::renderTags(
    spec$ui(AppState(env = new.env()), NULL)
  )$html

  expect_equal(
    lengths(regmatches(html, gregexpr('class="accordion-item"', html))), 5L
  )
  for (panel in c("Interface", "Output", "Data", "Documents",
                  "Optional extensions")) {
    expect_match(html, sprintf('data-value="%s"', panel), fixed = TRUE)
  }
  # Only the first panel is open.
  expect_equal(
    lengths(regmatches(
      html, gregexpr('class="accordion-collapse collapse show"', html)
    )), 1L
  )
  # Every control keeps its id.
  for (id in c("ui_mode", "theme", "density", "digits", "width",
               "edit_threshold", "stringsAsFactors", "use_markdown",
               "use_knitr")) {
    expect_match(html, sprintf('id="Options_%s"', id), fixed = TRUE)
  }
  # The old separators and sub-headings are gone: the panels are the titles.
  expect_false(grepl("<hr", html, fixed = TRUE))
  expect_false(grepl("<h6", html, fixed = TRUE))
})

test_that("an invalid Options field becomes an inline error", {
  spec <- get_dialog_spec("Options")
  state <- AppState(env = new.env())
  result <- spec$on_ok(
    list(Options_digits = 50, Options_width = 10,
         Options_edit_threshold = -1),
    state
  )
  errors <- dialog_field_errors(result)
  expect_match(errors$digits, "between 1 and 22")
  expect_match(errors$width, "between 40 and 300")
  expect_match(errors$edit_threshold, "cannot be negative")
  # The state is untouched when the dialog is rejected.
  expect_null(result$memory)
})

test_that("validation opens the closed panels before focusing", {
  js <- as.character(app_js())
  expect_match(js, "rcmdr-open-accordions", fixed = TRUE)
  expect_match(js, "rcmdrShowAccordions", fixed = TRUE)
  expect_match(js, "Collapse.getOrCreateInstance", fixed = TRUE)
  expect_match(js, "aria-expanded", fixed = TRUE)
  # Focus waits for the collapse transition, then lands on the first field
  # that actually has a box: a hidden conditional field is skipped.
  expect_match(js, "setTimeout", fixed = TRUE)
  expect_match(js, "candidates.push(el)", fixed = TRUE)
  expect_match(js, "el.getClientRects().length > 0", fixed = TRUE)

  css <- as.character(app_css())
  expect_match(css, ".rcmdr-dialog-grid > .accordion { grid-column: 1 / -1; }",
               fixed = TRUE)
})

test_that("the migrated model and test dialogs focus the invalid field", {
  env <- new.env()
  env$D <- data.frame(y = 1:6, x = 2 * (1:6),
                      g = factor(rep(c("a", "b"), 3)))
  state <- AppState(env = env)
  active_dataset(state, "D")

  reject <- function(id, input) {
    dialog_field_errors(get_dialog_spec(id)$on_ok(input, state))
  }

  errors <- reject("linearModel", list(
    linearModel_model = "1bad", linearModel_lhs = "y", linearModel_rhs = "x"
  ))
  expect_match(errors$model, "not a valid name")

  errors <- reject("linearModel", list(
    linearModel_model = "Fit", linearModel_lhs = "", linearModel_rhs = "x"
  ))
  expect_match(errors$lhs, "Left-hand side")

  errors <- reject("generalizedLinearModel", list(
    generalizedLinearModel_model = "Fit",
    generalizedLinearModel_lhs = "y", generalizedLinearModel_rhs = ""
  ))
  expect_match(errors$rhs, "Right-hand side")

  errors <- reject("linearRegressionModel", list(
    linearRegressionModel_model = "Reg", linearRegressionModel_response = "y",
    linearRegressionModel_predictors = character()
  ))
  expect_match(errors$predictors, "at least one predictor")

  errors <- reject("independentSamplesTTest", list(
    independentSamplesTTest_group = "",
    independentSamplesTTest_response = "y"
  ))
  expect_match(errors$group, "groups variable")

  errors <- reject("twoSampleProportionsTest", list(
    twoSampleProportionsTest_groups = "g",
    twoSampleProportionsTest_response = "g"
  ))
  expect_length(errors, 0L) # both variables are selected; no field error
  errors <- reject("twoSampleProportionsTest", list(
    twoSampleProportionsTest_groups = "",
    twoSampleProportionsTest_response = "g"
  ))
  expect_match(errors$groups, "groups and a response")

  errors <- reject("oneWayAnova", list(
    oneWayAnova_model = "Anova", oneWayAnova_group = "",
    oneWayAnova_response = "y"
  ))
  expect_match(errors$group, "groups factor")

  errors <- reject("singleProportionTest", list(
    singleProportionTest_x = ""
  ))
  expect_match(errors$x, "select a variable")
})
