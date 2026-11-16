# Chart models --------------------------------------------------------------

test_that("every model points at a real chart type and analysis family", {
  models <- chart_models()
  expect_gt(length(models), 20L)
  expect_equal(length(unique(names(models))), length(models))
  levels <- unname(chart_analysis_levels())
  for (id in names(models)) {
    model <- models[[id]]
    expect_true(nzchar(model$label), info = id)
    expect_true(model$analysis %in% levels, info = id)
    expect_false(is.null(chart_type(model$type)), info = id)
    expect_true(is.list(model$options), info = id)
    expect_true(is.list(model$theme), info = id)
  }
})

test_that("models build a specification skeleton without variables", {
  model <- chart_model("box_by_group")
  spec <- chart_model_spec(model, "D")
  expect_equal(spec$type, "boxplot")
  expect_equal(spec$theme$ggplot_theme, "bw")
  expect_length(chart_compose_children(spec), 0L)
  expect_true(length(chart_spec_validate(spec, chart_test_state())) > 0L)

  filled <- chart_spec("boxplot", "D", list(x = "y", group = "g"))
  expect_true(chart_spec_ready(filled, chart_test_state()))
})

test_that("the model table filters by analysis, type and query", {
  table <- chart_model_table()
  expect_true(all(c("id", "analysis", "type", "installed", "requires") %in%
                    names(table)))
  comparison <- chart_model_table(analysis = "comparison")
  expect_true(all(comparison$analysis == "comparison"))
  expect_gt(nrow(comparison), 0L)

  histograms <- chart_model_table(type = "histogram")
  expect_true(all(histograms$type == "histogram"))

  searched <- chart_model_table(query = "correl")
  expect_gt(nrow(searched), 0L)

  expect_equal(nrow(chart_model_table(query = "nothing matches this")), 0L)
})

test_that("models that need an extension report it", {
  table <- chart_model_table()
  statistical <- table[table$type == "stat_compare", , drop = FALSE]
  expect_gt(nrow(statistical), 0L)
  expect_equal(unique(statistical$requires), "ggstatsplot")
  expect_equal(unique(statistical$installed), chart_ext_available("ggstatsplot"))
})

test_that("the analysis helper falls back to the chart group", {
  expect_equal(chart_type_analysis(chart_type("boxplot")), "comparison")
  expect_equal(chart_type_analysis(chart_type("scatter")), "relationship")
  expect_equal(chart_type_analysis(chart_type("heatmap")), "categorical")
  expect_equal(chart_type_analysis(NULL), "univariate")
  expect_equal(chart_analysis_label("composite"), "Chart composition")
  expect_equal(chart_analysis_label("unknown"), "unknown")
})

test_that("model cards render an action per installed model", {
  table <- chart_model_table(analysis = "univariate")
  html <- htmltools::renderTags(chart_models_cards(table))$html
  expect_match(html, "chart_model_action")
  empty <- htmltools::renderTags(chart_models_cards(table[0, , drop = FALSE]))$html
  expect_match(empty, "No models match")
})
