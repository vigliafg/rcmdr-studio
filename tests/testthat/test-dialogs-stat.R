stats_state <- function() {
  set.seed(1)
  env <- new.env()
  env$D <- data.frame(
    y = rnorm(30), x = rnorm(30), z = rnorm(30),
    g = factor(rep(c("a", "b", "c"), 10)),
    h = factor(rep(c("u", "v"), 15)),
    s = letters[rep(1:5, 6)]
  )
  env$D$y2 <- env$D$y + rnorm(30)
  env$D$y3 <- env$D$y + rnorm(30)
  state <- AppState(env = env)
  active_dataset(state, "D")
  state
}

stats_inputs <- function() {
  list(
    frequencyDistribution = list(frequencyDistribution_variables = "g",
                                 frequencyDistribution_goodness = FALSE,
                                 frequencyDistribution_probs = ""),
    statisticsTable = list(statisticsTable_groups = "g",
                           statisticsTable_responses = c("y", "x"),
                           statisticsTable_statistic = "mean",
                           statisticsTable_other = ""),
    correlationMatrix = list(correlationMatrix_variables = c("y", "x"),
                             correlationMatrix_type = "Pearson",
                             correlationMatrix_use = "complete",
                             correlationMatrix_pvalues = FALSE),
    correlationTest = list(correlationTest_variables = c("y", "x"),
                           correlationTest_method = "pearson",
                           correlationTest_alternative = "two.sided"),
    NormalityTest = list(NormalityTest_variable = "y",
                         NormalityTest_test = "shapiro.test",
                         NormalityTest_groups = "",
                         NormalityTest_nclasses = ""),
    transformVariables = list(transformVariables_variables = c("y", "x"),
                              transformVariables_family = "bcPower",
                              transformVariables_rhs = ""),
    twoWayTable = list(twoWayTable_row = "g", twoWayTable_column = "h",
                       twoWayTable_percents = "none",
                       twoWayTable_tests_chisq = TRUE,
                       twoWayTable_tests_components = FALSE,
                       twoWayTable_tests_expected = FALSE,
                       twoWayTable_tests_fisher = FALSE,
                       twoWayTable_subset = ""),
    twoWayTableFromCounts = list(
      twoWayTableFromCounts_row = "g", twoWayTableFromCounts_column = "h",
      twoWayTableFromCounts_count = "y",
      twoWayTableFromCounts_percents = "none",
      twoWayTableFromCounts_tests_chisq = TRUE,
      twoWayTableFromCounts_tests_components = FALSE,
      twoWayTableFromCounts_tests_expected = FALSE,
      twoWayTableFromCounts_tests_fisher = FALSE,
      twoWayTableFromCounts_subset = ""
    ),
    multiWayTable = list(multiWayTable_row = "g", multiWayTable_column = "h",
                         multiWayTable_controls = "s",
                         multiWayTable_percents = "none",
                         multiWayTable_subset = ""),
    enterTable = list(enterTable_rowvar = "row", enterTable_colvar = "col",
                      enterTable_rownames = "A,B",
                      enterTable_colnames = "X,Y",
                      enterTable_counts = "1,2,3,4",
                      enterTable_percents = "none",
                      enterTable_tests_chisq = TRUE,
                      enterTable_tests_components = FALSE,
                      enterTable_tests_expected = FALSE,
                      enterTable_tests_fisher = FALSE,
                      enterTable_subset = ""),
    independentSamplesTTest = list(
      independentSamplesTTest_group = "h",
      independentSamplesTTest_response = "y",
      independentSamplesTTest_alternative = "two.sided",
      independentSamplesTTest_conf = 0.95,
      independentSamplesTTest_var_equal = FALSE
    ),
    pairedTTest = list(pairedTTest_x = "y", pairedTTest_y = "x",
                       pairedTTest_alternative = "two.sided",
                       pairedTTest_conf = 0.95),
    singleSampleTTest = list(singleSampleTTest_x = "y",
                             singleSampleTTest_alternative = "two.sided",
                             singleSampleTTest_mu = 0,
                             singleSampleTTest_conf = 0.95),
    oneWayAnova = list(oneWayAnova_model = "A1", oneWayAnova_group = "g",
                       oneWayAnova_response = "y",
                       oneWayAnova_pairwise = FALSE,
                       oneWayAnova_conf = 0.95,
                       oneWayAnova_welch = FALSE),
    multiWayAnova = list(multiWayAnova_model = "A2",
                         multiWayAnova_groups = c("g", "h"),
                         multiWayAnova_response = "y"),
    oneWayRepeatedMeasures = list(
      oneWayRepeatedMeasures_responses = c("y", "y2", "y3"),
      oneWayRepeatedMeasures_within = "time",
      oneWayRepeatedMeasures_levels = "t1,t2,t3",
      oneWayRepeatedMeasures_between = NULL,
      oneWayRepeatedMeasures_test = "univariate"
    ),
    twoWayRepeatedMeasures = list(
      twoWayRepeatedMeasures_responses = c("y", "x", "y2", "y3"),
      twoWayRepeatedMeasures_rowname = "row",
      twoWayRepeatedMeasures_rowlevels = "r1,r2",
      twoWayRepeatedMeasures_colname = "col",
      twoWayRepeatedMeasures_collevels = "c1,c2",
      twoWayRepeatedMeasures_between = NULL,
      twoWayRepeatedMeasures_test = "univariate"
    ),
    twoVariancesFTest = list(twoVariancesFTest_group = "h",
                             twoVariancesFTest_response = "y",
                             twoVariancesFTest_alternative = "two.sided",
                             twoVariancesFTest_conf = 0.95),
    BartlettTest = list(BartlettTest_response = "y",
                        BartlettTest_groups = "g",
                        BartlettTest_center = "median"),
    LeveneTest = list(LeveneTest_response = "y",
                      LeveneTest_groups = "g",
                      LeveneTest_center = "median"),
    sigmaTestMenu = list(sigmaTestMenu_x = "y",
                         sigmaTestMenu_alternative = "two.sided",
                         sigmaTestMenu_sigma = 1,
                         sigmaTestMenu_conf = 0.95),
    singleProportionTest = list(
      singleProportionTest_x = "g",
      singleProportionTest_test = "normal",
      singleProportionTest_alternative = "two.sided",
      singleProportionTest_p = 0.5,
      singleProportionTest_conf = 0.95
    ),
    twoSampleProportionsTest = list(
      twoSampleProportionsTest_groups = "h",
      twoSampleProportionsTest_response = "s",
      twoSampleProportionsTest_test = "normal",
      twoSampleProportionsTest_alternative = "two.sided",
      twoSampleProportionsTest_conf = 0.95
    ),
    twoSampleWilcoxonTest = list(
      twoSampleWilcoxonTest_group = "h",
      twoSampleWilcoxonTest_response = "y",
      twoSampleWilcoxonTest_test = "default",
      twoSampleWilcoxonTest_alternative = "two.sided"
    ),
    pairedWilcoxonTest = list(
      pairedWilcoxonTest_x = "y", pairedWilcoxonTest_y = "x",
      pairedWilcoxonTest_test = "default",
      pairedWilcoxonTest_alternative = "two.sided"
    ),
    KruskalWallisTest = list(KruskalWallisTest_group = "g",
                             KruskalWallisTest_response = "y"),
    FriedmanTest = list(FriedmanTest_responses = c("y", "x", "z")),
    onesampleWilcoxonTest = list(
      onesampleWilcoxonTest_x = "y",
      onesampleWilcoxonTest_test = "default",
      onesampleWilcoxonTest_alternative = "two.sided",
      onesampleWilcoxonTest_mu = 0
    ),
    Reliability = list(Reliability_variables = c("y", "x", "z")),
    principalComponents = list(
      principalComponents_variables = c("y", "x", "z"),
      principalComponents_correlations = TRUE,
      principalComponents_scree = FALSE,
      principalComponents_subset = ""
    ),
    factorAnalysis = list(
      factorAnalysis_variables = c("y", "x", "z"),
      factorAnalysis_factors = 1, factorAnalysis_rotation = "varimax",
      factorAnalysis_scores = "none", factorAnalysis_subset = ""
    ),
    CFA = list(CFA_model = "F1 -> y, NA, 1\nF1 -> x, lam1, NA\nF1 -> z, lam2, NA",
               CFA_name = "CFA.1"),
    kmeansClustering = list(
      kmeansClustering_variables = c("y", "x"),
      kmeansClustering_centers = 2, kmeansClustering_iter = 10,
      kmeansClustering_seeds = 10, kmeansClustering_summary = TRUE,
      kmeansClustering_plot = FALSE, kmeansClustering_assign = "",
      kmeansClustering_subset = ""
    ),
    hierarchicalCluster = list(
      hierarchicalCluster_solution = "H1",
      hierarchicalCluster_variables = c("y", "x"),
      hierarchicalCluster_method = "ward.D",
      hierarchicalCluster_distance = "euc",
      hierarchicalCluster_dendro = FALSE,
      hierarchicalCluster_subset = ""
    ),
    hclustSummary = list(hclustSummary_solution = "H1",
                         hclustSummary_clusters = 2,
                         hclustSummary_summary = TRUE,
                         hclustSummary_plot = FALSE),
    appendHclustGroup = list(appendHclustGroup_solution = "H1",
                             appendHclustGroup_clusters = 2,
                             appendHclustGroup_label = "cluster"),
    linearRegressionModel = list(
      linearRegressionModel_model = "M1",
      linearRegressionModel_response = "y",
      linearRegressionModel_predictors = c("x", "z"),
      linearRegressionModel_subset = "",
      linearRegressionModel_weights = "",
      linearRegressionModel_remove = ""
    ),
    generalizedLinearModel = list(
      generalizedLinearModel_model = "G1",
      generalizedLinearModel_lhs = "h",
      generalizedLinearModel_rhs = "y",
      generalizedLinearModel_subset = "",
      generalizedLinearModel_weights = "",
      generalizedLinearModel_remove = "",
      generalizedLinearModel_family = "binomial",
      generalizedLinearModel_link = "logit"
    ),
    multinomialLogitModel = list(
      multinomialLogitModel_model = "MN1",
      multinomialLogitModel_lhs = "g",
      multinomialLogitModel_rhs = "y",
      multinomialLogitModel_subset = "",
      multinomialLogitModel_remove = ""
    ),
    ordinalRegressionModel = list(
      ordinalRegressionModel_model = "O1",
      ordinalRegressionModel_lhs = "s",
      ordinalRegressionModel_rhs = "y",
      ordinalRegressionModel_subset = "",
      ordinalRegressionModel_remove = "",
      ordinalRegressionModel_method = "logistic"
    ),
    linearMixedModel = list(
      linearMixedModel_model = "L1",
      linearMixedModel_lhs = "y",
      linearMixedModel_rhs = "x + (1 | g)",
      linearMixedModel_subset = "",
      linearMixedModel_remove = "",
      linearMixedModel_reml = TRUE
    ),
    generalizedLinearMixedModel = list(
      generalizedLinearMixedModel_model = "GL1",
      generalizedLinearMixedModel_lhs = "h",
      generalizedLinearMixedModel_rhs = "y + (1 | g)",
      generalizedLinearMixedModel_subset = "",
      generalizedLinearMixedModel_remove = "",
      generalizedLinearMixedModel_family = "binomial",
      generalizedLinearMixedModel_link = "logit"
    )
  )
}

test_that("every Statistics dialog validates and returns commands", {
  inputs <- stats_inputs()
  for (id in names(inputs)) {
    state <- stats_state()
    if (id %in% c("hclustSummary", "appendHclustGroup")) {
      run_command(state, cmd_hclust("D", "H1", c("y", "x"), dendro = FALSE))
    }
    spec <- get_dialog_spec(id)
    result <- tryCatch(
      spec$on_ok(inputs[[id]], state),
      error = function(e) list(error = conditionMessage(e))
    )
    expect_null(result$error)
    expect_true(length(result$commands %||% character()) > 0L)
  }
})

test_that("Statistics dialogs reject invalid selections", {
  state <- stats_state()

  expect_match(
    get_dialog_spec("correlationTest")$on_ok(
      list(correlationTest_variables = "y"), state)$error,
    "exactly two"
  )
  expect_match(
    get_dialog_spec("independentSamplesTTest")$on_ok(
      list(independentSamplesTTest_group = "", independentSamplesTTest_response = "y"),
      state)$error,
    "groups variable"
  )
  expect_match(
    get_dialog_spec("oneWayAnova")$on_ok(
      list(oneWayAnova_model = "1bad", oneWayAnova_group = "g",
           oneWayAnova_response = "y"), state)$error,
    "not a valid name"
  )
  expect_match(
    get_dialog_spec("twoWayTable")$on_ok(
      list(twoWayTable_row = "g", twoWayTable_column = "g"), state)$error,
    "same"
  )
})

# Form vocabulary -----------------------------------------------------------

test_that("statistics dialogs use segmented controls for short choices", {
  state <- stats_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, NULL))$html
  }

  # Shared helper: the alternative hypothesis is Three short labels.
  default_test <- render("independentSamplesTTest")
  expect_match(default_test, "rcmdr-segmented", fixed = TRUE)
  expect_match(default_test,
               'name="independentSamplesTTest_alternative"', fixed = TRUE)
  expect_match(default_test, 'value="greater"', fixed = TRUE)

  # Univariate / multivariate is a two-choice question.
  repeated <- render("oneWayRepeatedMeasures")
  expect_match(repeated, "rcmdr-segmented", fixed = TRUE)
  expect_match(repeated, 'name="oneWayRepeatedMeasures_test"', fixed = TRUE)
  expect_match(repeated, 'value="multivariate"', fixed = TRUE)

  # The two-variance test has its own alternatives; Levene's test swaps
  # median and mean.
  variance <- render("twoVariancesFTest")
  expect_match(variance, 'name="twoVariancesFTest_alternative"', fixed = TRUE)
  expect_match(variance, 'value="less"', fixed = TRUE)
  levene <- render("LeveneTest")
  expect_match(levene, 'name="LeveneTest_center"', fixed = TRUE)
  expect_match(levene, 'value="mean"', fixed = TRUE)

  # Factor analysis: rotation and scores are three short names each.
  factor_html <- render("factorAnalysis")
  expect_match(factor_html, 'name="factorAnalysis_rotation"', fixed = TRUE)
  expect_match(factor_html, 'name="factorAnalysis_scores"', fixed = TRUE)

  # The mixed model family keeps the three short family names.
  mixed <- render("generalizedLinearMixedModel")
  expect_match(mixed, 'name="generalizedLinearMixedModel_family"', fixed = TRUE)

  # The summaries type is a three-way choice.
  summaries <- render("numericalSummaries")
  expect_match(summaries, 'name="numericalSummaries_type"', fixed = TRUE)
})

test_that("statistics dialogs use number fields where the value is a number", {
  state <- stats_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, NULL))$html
  }

  # Every id below used to render as a spinner; each is a command parameter.
  cases <- list(
    independentSamplesTTest = "conf",
    singleSampleTTest = "mu",
    sigmaTestMenu = "sigma",
    singleProportionTest = "p",
    factorAnalysis = "factors",
    kmeansClustering = "centers",
    hclustSummary = "clusters"
  )
  for (id in names(cases)) {
    html <- render(id)
    field <- paste0(id, "_", cases[[id]])
    expect_match(html, paste0('id="', field, '"'), fixed = TRUE)
    expect_match(html, 'type="number"', fixed = TRUE)
    expect_false(grepl(
      paste0('id="', field, '"[^>]*type="text"'), html
    ))
  }

  # k-means has three numbers in a row: clusters, iterations and starts.
  kmeans <- render("kmeansClustering")
  expect_equal(
    lengths(regmatches(kmeans, gregexpr('type="number"', kmeans))), 3L
  )
})

test_that("long option labels stay radio lists, not pills", {
  state <- stats_state()
  render <- function(id) {
    htmltools::renderTags(get_dialog_spec(id)$ui(state, NULL))$html
  }

  # Six test names with long labels, five percentage layouts, seven clustering
  # methods: a strip would wrap into a wall.
  for (id in c("NormalityTest", "twoWayTable", "hierarchicalCluster")) {
    html <- render(id)
    expect_match(html, "shiny-input-radiogroup")
    expect_false(grepl("rcmdr-segmented", html, fixed = TRUE))
  }

  # Checkboxes in these dialogs are command parameters, not preferences: they
  # keep the checkbox, never the switch.
  expect_false(grepl("rcmdr-switch", render("kmeansClustering"), fixed = TRUE))
})

test_that("the frequency dialog separates variables from its tests", {
  env <- new.env()
  env$D <- data.frame(y = 1:6, g = factor(rep(c("a", "b"), 3)))
  state <- AppState(env = env)
  active_dataset(state, "D")

  html <- htmltools::renderTags(
    get_dialog_spec("frequencyDistribution")$ui(state, NULL)
  )$html

  expect_match(html, 'id="frequencyDistribution_settings"', fixed = TRUE)
  expect_equal(
    lengths(regmatches(html, gregexpr('class="accordion-item"', html))), 2L
  )
  expect_setequal(
    regmatches(html, gregexpr('data-value="[^"]*"', html))[[1L]],
    c('data-value="Variables"', 'data-value="Tests"')
  )
  expect_match(html, 'data-value="Variables"', fixed = TRUE)
  expect_match(html, "collapse show", fixed = TRUE)

  # The variable listbox stays in its panel, the test parameters in the other.
  split <- regexpr('data-value="Tests"', html, fixed = TRUE)[[1L]]
  variables <- substr(html, 1, split - 1L)
  tests <- substr(html, split, nchar(html))
  expect_match(variables, 'id="frequencyDistribution_variables"', fixed = TRUE)
  expect_match(tests, 'id="frequencyDistribution_goodness"', fixed = TRUE)
  expect_match(tests, 'id="frequencyDistribution_probs"', fixed = TRUE)
  expect_false(grepl('id="frequencyDistribution_goodness"', variables,
                     fixed = TRUE))

  # All three ids the command builder reads are still present.
  for (name in c("variables", "goodness", "probs")) {
    expect_equal(
      lengths(regmatches(html, gregexpr(
        sprintf('id="frequencyDistribution_%s"', name), html
      ))), 1L, info = name
    )
  }
})
