# Chart models --------------------------------------------------------------
#
# A model is a ready-made chart recipe: a chart type plus the theme and options
# that make it answer a specific question.  Models are grouped by analysis
# family and by chart type, and opening one fills the builder without choosing
# variables: the data mapping stays with the user.

#' Analysis families used by the registries
#' @keywords internal
chart_analysis_levels <- function() {
  stats::setNames(
    c("univariate", "comparison", "repeated", "relationship",
      "categorical", "composition", "models", "time", "composite"),
    c(
      tr("Descriptive (one variable)"),
      tr("Group comparison"),
      tr("Repeated measures"),
      tr("Relationship and correlation"),
      tr("Categorical association"),
      tr("Composition"),
      tr("Models and coefficients"),
      tr("Time series"),
      tr("Chart composition")
    )
  )
}

#' Analysis family of a chart type
#' @keywords internal
chart_type_analysis <- function(info) {
  if (is.null(info)) return("univariate")
  analysis <- info$analysis %||% ""
  if (nzchar(analysis)) return(analysis)
  explicit <- c(
    histogram = "univariate", density = "univariate", ecdf = "univariate",
    dot = "univariate", bar = "univariate", qq = "relationship",
    boxplot = "comparison", violin = "comparison", means = "comparison",
    strip = "comparison", scatter = "relationship",
    xyplot = "relationship", density_2d = "relationship",
    heatmap = "categorical", line = "time"
  )
  type <- info$id %||% ""
  if (nzchar(type) && type %in% names(explicit)) return(unname(explicit[type]))
  switch(
    info$group %||% "",
    distribution = "univariate",
    relationship = "relationship",
    comparison = "comparison",
    composition = "composition",
    models = "models",
    time = "time",
    "univariate"
  )
}

#' Label of an analysis family
#' @keywords internal
chart_analysis_label <- function(analysis) {
  levels <- chart_analysis_levels()
  index <- match(analysis %||% "", unname(levels))
  if (is.na(index)) return(analysis %||% "")
  names(levels)[[index]]
}

chart_model_entry <- function(id, label, analysis, type, description,
                              options = list(), theme = list(),
                              requires = character()) {
  list(
    id = id,
    label = label,
    analysis = analysis,
    type = type,
    description = description,
    options = options,
    theme = theme,
    requires = requires
  )
}

#' Catalogue of ready-made chart models
#' @keywords internal
chart_models <- function() {
  models <- list(
    # Descriptive ---------------------------------------------------------
    chart_model_entry(
      "hist_default", tr("Histogram"), "univariate", "histogram",
      tr("Distribution of one numeric variable with automatic bins.")
    ),
    chart_model_entry(
      "hist_bins", tr("Histogram with fixed bins"), "univariate", "histogram",
      tr("Distribution with a fixed bin width for comparisons."),
      options = list(binwidth = 0.5)
    ),
    chart_model_entry(
      "density_group", tr("Density by group"), "univariate", "density",
      tr("Smoothed distribution, one curve per group.")
    ),
    chart_model_entry(
      "ecdf_group", tr("Cumulative distribution"), "univariate", "ecdf",
      tr("Empirical cumulative distribution, optionally by group."),
      theme = list(ggplot_theme = "classic")
    ),
    chart_model_entry(
      "bar_counts", tr("Counts by category"), "univariate", "bar",
      tr("Frequency of each level of a categorical variable.")
    ),
    # Comparison ----------------------------------------------------------
    chart_model_entry(
      "box_by_group", tr("Box plot by group"), "comparison", "boxplot",
      tr("Compare the spread of a numeric variable across groups."),
      theme = list(ggplot_theme = "bw")
    ),
    chart_model_entry(
      "violin_by_group", tr("Violin plot by group"), "comparison", "violin",
      tr("Distribution shape per group with an inner box plot.")
    ),
    chart_model_entry(
      "strip_by_group", tr("Strip chart by group"), "comparison", "strip",
      tr("Every observation per group, with jitter."),
      options = list(jitter = 0.1)
    ),
    chart_model_entry(
      "means_by_group", tr("Means with error bars"), "comparison", "means",
      tr("Group means with their confidence intervals.")
    ),
    # Relationship --------------------------------------------------------
    chart_model_entry(
      "scatter_smooth", tr("Scatter with trend"), "relationship", "scatter",
      tr("Two numeric variables with a linear trend and confidence band."),
      options = list(smooth_method = "lm", smooth_se = TRUE)
    ),
    chart_model_entry(
      "scatter_group", tr("Scatter by group"), "relationship", "scatter",
      tr("Trend lines per group to compare slopes."),
      options = list(smooth_method = "lm", smooth_se = TRUE),
      theme = list(ggplot_theme = "bw")
    ),
    chart_model_entry(
      "density_2d", tr("Two-dimensional density"), "relationship", "density_2d",
      tr("Where two numeric variables concentrate together.")
    ),
    chart_model_entry(
      "qq_normality", tr("Quantile comparison"), "relationship", "qq",
      tr("Check a variable against the normal distribution.")
    ),
    # Categorical association ---------------------------------------------
    chart_model_entry(
      "heatmap_two", tr("Heat map of two factors"), "categorical", "heatmap",
      tr("Counts of two categorical variables on a colour scale.")
    ),
    # Composition ---------------------------------------------------------
    chart_model_entry(
      "bar_stacked", tr("Stacked shares"), "composition", "bar",
      tr("Category shares stacked to 100%."),
      options = list(position = "fill"),
      theme = list(ggplot_theme = "light")
    ),
    chart_model_entry(
      "bar_grouped", tr("Grouped bars"), "composition", "bar",
      tr("Side-by-side bars for two categorical variables."),
      options = list(position = "dodge")
    ),
    # Time ----------------------------------------------------------------
    chart_model_entry(
      "time_line", tr("Series over time"), "time", "line",
      tr("One line per group along a numeric or date axis.")
    ),
    chart_model_entry(
      "xyplot_groups", tr("Several series"), "time", "xyplot",
      tr("Several numeric variables against a common index.")
    ),
    # Models --------------------------------------------------------------
    chart_model_entry(
      "residuals", tr("Residuals vs fitted"), "models", "scatter",
      tr("Diagnostic plot for a fitted model."),
      options = list(smooth_method = "lm")
    ),
    # Publication ---------------------------------------------------------
    chart_model_entry(
      "pub_hist", tr("Editorial histogram"), "univariate", "histogram",
      tr("Histogram with the hrbrthemes editorial typography."),
      theme = list(ggplot_theme = "theme_ipsum"),
      requires = "hrbrthemes"
    ),
    chart_model_entry(
      "pub_scatter", tr("Publication scatter"), "relationship", "scatter",
      tr("Scatter with the hrbrthemes RC theme and comma axis labels."),
      options = list(smooth_method = "lm", smooth_se = TRUE,
                     x_format = "comma", y_format = "comma"),
      theme = list(ggplot_theme = "theme_ipsum_rc"),
      requires = "hrbrthemes"
    ),
    # Statistical charts --------------------------------------------------
    chart_model_entry(
      "stat_compare_model", tr("Group difference with test"), "comparison",
      "stat_compare",
      tr("Boxes or violins plus the test result in the subtitle."),
      options = list(test_type = "parametric", pairwise = TRUE),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_compare_np", tr("Group difference (non-parametric)"), "comparison",
      "stat_compare",
      tr("Rank-based comparison for skewed or small samples."),
      options = list(test_type = "nonparametric", pairwise = TRUE),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_within_model", tr("Repeated measures with test"), "repeated",
      "stat_within",
      tr("Conditions measured on the same units, with the paired test."),
      options = list(test_type = "parametric", paired = TRUE),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_hist_model", tr("Distribution with test"), "univariate",
      "stat_hist",
      tr("Histogram with central tendency and effect size."),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_scatter_model", tr("Correlation with test"), "relationship",
      "stat_scatter",
      tr("Scatter plot with the correlation coefficient in the subtitle."),
      options = list(test_type = "nonparametric"),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_corrmat_model", tr("Correlation matrix with test"), "relationship",
      "stat_corrmat",
      tr("Correlation matrix of several numeric variables."),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_pie_model", tr("Proportions with test"), "categorical",
      "stat_pie",
      tr("Category shares with a goodness-of-fit test."),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_bar_model", tr("Two-way table with test"), "categorical",
      "stat_bar",
      tr("Bars for two categorical variables with a contingency test."),
      requires = "ggstatsplot"
    ),
    chart_model_entry(
      "stat_coef_model", tr("Model coefficients with test"), "models",
      "stat_coef",
      tr("Coefficient plot of an estimated model, with its p-values."),
      requires = "ggstatsplot"
    ),
    # Chart composition ---------------------------------------------------
    chart_model_entry(
      "compose_pair", tr("Two charts side by side"), "composite", "compose",
      tr("Place two gallery charts next to each other with shared tags."),
      options = list(layout = "1x2"),
      requires = "patchwork"
    ),
    chart_model_entry(
      "compose_grid", tr("Grid of four charts"), "composite", "compose",
      tr("A two by two grid with collected legends."),
      options = list(layout = "2x2"),
      requires = "patchwork"
    )
  )
  stats::setNames(models, vapply(models, function(model) model$id,
                                 character(1)))
}

#' A model by identifier
#' @keywords internal
chart_model <- function(id) {
  chart_models()[[id %||% ""]]
}

#' Models filtered by analysis family and chart type
#' @keywords internal
chart_model_table <- function(analysis = NULL, type = NULL, query = "") {
  models <- chart_models()
  rows <- lapply(models, function(model) {
    info <- chart_type(model$type)
    data.frame(
      id = model$id,
      label = model$label,
      analysis = model$analysis,
      type = model$type,
      type_label = info$label %||% model$type,
      description = model$description,
      installed = chart_ext_available(model$requires),
      requires = paste(model$requires, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })
  table <- do.call(rbind, rows)
  if (!is.null(analysis) && nzchar(analysis) && !identical(analysis, "all")) {
    table <- table[table$analysis == analysis, , drop = FALSE]
  }
  if (!is.null(type) && nzchar(type) && !identical(type, "all")) {
    table <- table[table$type == type, , drop = FALSE]
  }
  query <- trimws(query %||% "")
  if (nzchar(query)) {
    pattern <- tolower(query)
    hit <- grepl(pattern, tolower(table$label), fixed = TRUE) |
      grepl(pattern, tolower(table$description), fixed = TRUE) |
      grepl(pattern, tolower(table$type_label), fixed = TRUE)
    table <- table[hit, , drop = FALSE]
  }
  rownames(table) <- NULL
  table
}

#' Chart type choices grouped by analysis family
#' @keywords internal
chart_type_choices_by_analysis <- function(engine = "ggplot2") {
  choices <- chart_type_choices(engine)
  groups <- list()
  for (label in names(choices)) {
    id <- unname(choices[[label]])
    if (length(id) != 1L) next
    group <- chart_analysis_label(chart_type_analysis(chart_type(id)))
    groups[[group]] <- c(groups[[group]], stats::setNames(id, label))
  }
  groups
}

#' Specification skeleton for a model
#'
#' Variables are intentionally left empty: the model describes the question,
#' the user picks the columns in the builder.
#' @param model A model entry from [chart_models()].
#' @param dataset Name of the data set to chart.
#' @keywords internal
chart_model_spec <- function(model, dataset = "data") {
  info <- chart_type(model$type)
  if (is.null(info)) return(NULL)
  chart_spec(
    type = model$type,
    dataset = dataset,
    options = utils::modifyList(info$defaults %||% list(),
                                model$options %||% list()),
    theme = model$theme %||% list()
  )
}
