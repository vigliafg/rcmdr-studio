# ggstatsplot charts --------------------------------------------------------

test_that("the statistical types are registered and gated", {
  types <- chart_stat_types()
  expect_setequal(names(types), chart_stat_type_ids())
  for (id in names(types)) {
    info <- types[[id]]
    expect_true(nzchar(info$label), info = id)
    expect_identical(info$requires, "ggstatsplot", info = id)
    expect_identical(chart_type(id)$engines, "ggplot2", info = id)
    expect_true(is.function(info$controls), info = id)
    expect_true(chart_stat_type(id), info = id)
  }
  expect_true(all(chart_stat_type_ids() %in% chart_type_ids()))
  expect_false(chart_stat_type("histogram"))
})

test_that("statistical types are hidden when ggstatsplot is missing", {
  skip_if(chart_ext_available("ggstatsplot"),
          "ggstatsplot is installed")
  choices <- chart_type_choices()
  expect_false(any(chart_stat_type_ids() %in% unname(choices)))
  spec <- chart_spec("stat_compare", "D", list(x = "g", y = "y"))
  expect_match(chart_spec_validate(spec, chart_test_state()),
               "needs the ggstatsplot package")
})

test_that("the generated ggstatsplot commands map the mappings", {
  compare <- chart_spec(
    "stat_compare", "D", list(x = "g", y = "y"),
    options = list(test_type = "nonparametric", pairwise = TRUE)
  )
  command <- chart_stat_object(compare)
  expect_match(command, "ggstatsplot::ggbetweenstats\\(", perl = TRUE)
  expect_match(command, "x = g", fixed = TRUE)
  expect_match(command, "y = y", fixed = TRUE)
  expect_match(command, "type = \"nonparametric\"", fixed = TRUE)
  expect_match(command, "pairwise.display = 'significant'", fixed = TRUE)
  expect_match(command, "ggtheme = ggplot2::theme_", fixed = TRUE)

  within <- chart_spec(
    "stat_within", "D", list(x = "g", y = "y"),
    options = list(paired = TRUE)
  )
  expect_match(chart_stat_object(within), "paired = TRUE", fixed = TRUE)

  hist <- chart_spec("stat_hist", "D", list(x = "y"))
  expect_match(chart_stat_object(hist), "ggstatsplot::gghistostats")

  dot <- chart_spec("stat_dot", "D", list(x = "y", y = "g"))
  expect_match(chart_stat_object(dot), "y = g", fixed = TRUE)

  scatter <- chart_spec("stat_scatter", "D", list(x = "x", y = "y"))
  expect_match(chart_stat_object(scatter), "ggstatsplot::ggscatterstats")

  matrix <- chart_spec("stat_corrmat", "D", list(vars = c("x", "y")))
  expect_match(chart_stat_object(matrix),
               "cor.vars = c(x, y)", fixed = TRUE)

  pie <- chart_spec("stat_pie", "D", list(x = "g", y = "g2"))
  expect_match(chart_stat_object(pie), "y = g2", fixed = TRUE)

  bar <- chart_spec("stat_bar", "D", list(x = "g", y = "g2"))
  expect_match(chart_stat_object(bar), "ggstatsplot::ggbarstats")

  coef <- chart_spec("stat_coef", "D", list(model = "fit"))
  expect_match(chart_stat_object(coef), "x = fit", fixed = TRUE)
})

test_that("every statistical chart renders when ggstatsplot is installed", {
  skip_if_not_installed("ggstatsplot")
  state <- chart_test_state()
  run_command(state, "fit <- lm(y ~ x, data = D)")
  mappings <- list(
    stat_compare = list(x = "g", y = "y"),
    stat_within = list(x = "g", y = "y"),
    stat_hist = list(x = "y"),
    stat_dot = list(x = "y", y = "g"),
    stat_scatter = list(x = "x", y = "y"),
    stat_corrmat = list(vars = c("x", "y")),
    stat_pie = list(x = "g"),
    stat_bar = list(x = "g", y = "g2"),
    stat_coef = list(model = "fit")
  )
  for (id in names(mappings)) {
    spec <- chart_spec(id, "D", mappings[[id]])
    expect_length(chart_spec_validate(spec, state), 0L)
    # The synthetic fixture is perfectly collinear: lm warns about the fit.
    preview <- suppressWarnings(
      chart_preview(state, spec, width = 400, height = 300)
    )
    expect_equal(preview$type, "image", info = paste(id, preview$error))
  }
})

test_that("the model slot lists the estimated models", {
  state <- chart_test_state()
  expect_equal(chart_mapping_choices(state, list(kind = "model")),
               list_all_models(state))
  spec <- chart_spec("stat_coef", "D")
  html <- htmltools::renderTags(chart_mapping_controls(state, spec))$html
  expect_match(html, "Estimate a model first")
})
