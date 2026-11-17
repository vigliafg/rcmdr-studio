models_state <- function() {
  set.seed(1)
  env <- new.env()
  env$D <- data.frame(
    y = rnorm(30), x = rnorm(30), z = rnorm(30),
    g = factor(rep(c("a", "b", "c"), 10))
  )
  env$fit <- stats::lm(y ~ x, data = env$D)
  state <- AppState(env = env)
  active_dataset(state, "D")
  active_model(state, "fit")
  state
}

test_that("model dialogs use segmented controls for short choices", {
  state <- models_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, list()))$html
  }

  # Stepwise selection names two short criteria; the direction keeps its radio
  # list because "Backward/forward" is a label, not a pill.
  stepwise <- render("stepwiseRegression")
  expect_match(stepwise, "rcmdr-segmented", fixed = TRUE)
  expect_match(stepwise, 'name="stepwiseRegression_criterion"', fixed = TRUE)
  expect_match(stepwise, 'value="AIC"', fixed = TRUE)
  expect_match(stepwise, "shiny-input-radiogroup")

  anova <- render("anovaTable")
  expect_match(anova, 'name="anovaTable_type"', fixed = TRUE)
  expect_match(anova, 'name="anovaTable_test"', fixed = TRUE)
  expect_match(anova, 'value="Chisq"', fixed = TRUE)

  compare <- render("compareModels")
  expect_match(compare, 'name="compareModels_test"', fixed = TRUE)

  # Bootstrap: percentiles, normal and basic intervals, and the resampling
  # unit, are one strip each.
  bootstrap <- render("Bootstrap")
  expect_match(bootstrap, 'name="Bootstrap_type"', fixed = TRUE)
  expect_match(bootstrap, 'name="Bootstrap_method"', fixed = TRUE)
  expect_match(bootstrap, 'value="residual"', fixed = TRUE)
})

test_that("model dialogs use number fields for counts and levels", {
  state <- models_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, list()))$html
  }

  bootstrap <- render("Bootstrap")
  expect_match(bootstrap, 'id="Bootstrap_samples"', fixed = TRUE)
  expect_match(bootstrap, 'id="Bootstrap_level"', fixed = TRUE)
  expect_equal(
    lengths(regmatches(bootstrap, gregexpr('type="number"', bootstrap))), 2L
  )

  subset <- render("subsetRegression")
  expect_match(subset, 'id="subsetRegression_nbest"', fixed = TRUE)
  expect_match(subset, 'type="number"', fixed = TRUE)

  # Identifying points in a plot is a count, not a text field.
  influence <- render("InfluencePlot")
  expect_match(influence, 'id="InfluencePlot_n"', fixed = TRUE)
  expect_match(influence, 'type="number"', fixed = TRUE)
  # Its three long methods stay a radio list.
  expect_false(grepl("rcmdr-segmented", influence, fixed = TRUE))
})

test_that("document dialogs use segmented controls for short levels", {
  state <- models_state()
  spec <- get_dialog_spec("insertSection")
  if (is.null(spec)) spec <- get_dialog_spec("insertHeading")
  html <- htmltools::renderTags(spec$ui(state, list()))$html
  expect_match(html, "rcmdr-segmented", fixed = TRUE)
  expect_match(html, 'value="3"', fixed = TRUE)
  expect_match(html, "<span>Subsubsection</span>", fixed = TRUE)
})
