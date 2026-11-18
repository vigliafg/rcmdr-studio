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

test_that("model dialogs separate the model, its data and its options", {
  state <- models_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, list()))$html
  }
  panel_values <- function(html) {
    sub('data-value="([^"]*)"', "\\1",
        regmatches(html, gregexpr('data-value="[^"]*"', html))[[1L]])
  }
  panel <- function(html, value) {
    start <- regexpr(sprintf('data-value="%s"', value), html, fixed = TRUE)[[1L]]
    body <- substring(html, start)
    end <- regexpr('data-value="', substring(body, 20), fixed = TRUE)[[1L]]
    if (end > 0L) body <- substr(body, 1L, end + 18L)
    body
  }

  expect_setequal(panel_values(render("linearModel")),
                  c("Model", "Data", "Options"))
  expect_setequal(panel_values(render("generalizedLinearModel")),
                  c("Model", "Data", "Options"))
  expect_setequal(panel_values(render("ordinalRegressionModel")),
                  c("Model", "Data", "Options"))
  expect_setequal(panel_values(render("linearMixedModel")),
                  c("Model", "Data", "Options"))
  expect_setequal(panel_values(render("generalizedLinearMixedModel")),
                  c("Model", "Data", "Options"))
  # A type without extra parameters gets two panels, not an empty third.
  expect_setequal(panel_values(render("multinomialLogitModel")),
                  c("Model", "Data"))

  for (id in c("linearModel", "generalizedLinearModel", "multinomialLogitModel")) {
    html <- render(id)
    expect_match(html, sprintf('id="%s_settings"', id), fixed = TRUE)
    expect_equal(
      lengths(regmatches(html, gregexpr("collapse show", html))), 1L
    )
    # Every id the dialog reads is still there, once.
    for (name in c("model", "lhs", "rhs", "insert_var", "insert", "op_plus",
                   "subset", "remove")) {
      expect_equal(
        lengths(regmatches(html, gregexpr(
          sprintf('id="%s_%s"', id, name), html
        ))), 1L, info = paste(id, name)
      )
    }
  }

  # Model owns the formula, Data the rows, Options the family.
  glm <- render("generalizedLinearModel")
  model_panel <- panel(glm, "Model")
  data_panel <- panel(glm, "Data")
  options_panel <- panel(glm, "Options")
  expect_match(model_panel, 'id="generalizedLinearModel_lhs"', fixed = TRUE)
  expect_match(model_panel, 'id="generalizedLinearModel_op_plus"', fixed = TRUE)
  expect_match(data_panel, 'id="generalizedLinearModel_subset"', fixed = TRUE)
  expect_match(data_panel, 'id="generalizedLinearModel_weights"', fixed = TRUE)
  expect_match(data_panel, 'id="generalizedLinearModel_remove"', fixed = TRUE)
  expect_match(options_panel, 'id="generalizedLinearModel_family"',
               fixed = TRUE)
  expect_match(options_panel, 'id="generalizedLinearModel_link"', fixed = TRUE)
  expect_false(grepl('id="generalizedLinearModel_family"', data_panel,
                     fixed = TRUE))

  # The formula helper and its buttons keep working in the Model panel.
  lm <- render("linearModel")
  expect_match(panel(lm, "Model"), 'id="linearModel_insert_var"', fixed = TRUE)
  expect_match(panel(lm, "Data"), 'id="linearModel_weights"', fixed = TRUE)
  expect_match(panel(lm, "Options"), "generated on OK", fixed = TRUE)
})
