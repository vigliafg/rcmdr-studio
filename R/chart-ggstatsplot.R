# ggstatsplot charts --------------------------------------------------------
#
# Each chart carries the result of its statistical test in the subtitle.
# Everything is gated: the types are hidden when ggstatsplot is missing, the
# options that need an extra package are disabled and the generated code stays
# valid R even when a test type is unavailable.

#' Statistical approaches offered by the ggstatsplot types
#' @keywords internal
chart_stat_types_choices <- function() {
  stats::setNames(
    c("parametric", "nonparametric", "robust", "bayes"),
    c(tr("Parametric"), tr("Non-parametric"), tr("Robust"), tr("Bayesian"))
  )
}

#' Default options shared by the ggstatsplot types
#' @keywords internal
chart_stat_defaults <- function() {
  list(
    test_type = "parametric",
    p_adjust = "holm",
    digits = 2L,
    results_subtitle = TRUE,
    bf_message = FALSE,
    pairwise = FALSE,
    paired = FALSE,
    central = "mean",
    type = "parametric"
  )
}

chart_stat_theme <- function(spec) {
  chart_gg_theme(spec)
}

chart_stat_common <- function(spec, options, extras = character()) {
  args <- c(
    sprintf("type = %s", chart_quote(options$test_type)),
    sprintf("digits = %d", as.integer(options$digits %||% 2L)),
    sprintf("results.subtitle = %s",
            if (isTRUE(options$results_subtitle)) "TRUE" else "FALSE")
  )
  if (isTRUE(options$pairwise)) {
    args <- c(args, "pairwise.display = 'significant'",
              sprintf("p.adjust.method = %s", chart_quote(options$p_adjust)))
  }
  if (isTRUE(options$bf_message)) {
    args <- c(args, "bf.message = TRUE")
  }
  args <- c(extras, args)
  theme <- chart_stat_theme(spec)
  if (!is.null(theme) && nzchar(theme)) args <- c(args, sprintf("ggtheme = %s", theme))
  args
}

#' Controls shared by the ggstatsplot types
#' @keywords internal
chart_stat_controls <- function(spec, extras = NULL) {
  options <- utils::modifyList(chart_stat_defaults(), spec$options %||% list())
  htmltools::tagList(
    selectInput(
      "chart_opt_test_type", tr("Statistical approach"),
      choices = chart_stat_types_choices(),
      selected = options$test_type %||% "parametric", width = "100%"
    ),
    selectInput(
      "chart_opt_p_adjust", tr("p-value adjustment"),
      choices = stats::setNames(
        c("holm", "bonferroni", "fdr", "none"),
        c("Holm", "Bonferroni", "FDR", "None")
      ),
      selected = options$p_adjust %||% "holm", width = "100%"
    ),
    number_input("chart_opt_digits", tr("Digits"), options$digits %||% 2L,
                 min = 0, max = 6, step = 1),
    if (!is.null(extras)) extras,
    htmltools::div(
      class = "rcmdr-check-stack",
      checkboxInput("chart_opt_results_subtitle", tr("Test result in subtitle"),
                    value = isTRUE(options$results_subtitle)),
      checkboxInput("chart_opt_pairwise", tr("Show significant pairwise tests"),
                    value = isTRUE(options$pairwise))
    ),
    if (!chart_ext_available("BayesFactor")) {
      help_text(tr("The Bayesian approach needs the BayesFactor package."))
    } else {
      NULL
    }
  )
}

#' ggstatsplot chart types
#' @keywords internal
chart_stat_types <- function() {
  control <- function(spec) chart_stat_controls(spec)
  list(
    stat_compare = list(
      label = tr("Compare groups (statistics)"),
      icon = "boxplot",
      group = "comparison",
      analysis = "comparison",
      description = tr(
        "Group means or medians with the test result in the subtitle (ggbetweenstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        y = list(label = tr("Outcome (numeric)"), kind = "numeric"),
        x = list(label = tr("Groups"), kind = "factor"),
        facet = list(label = tr("Facets"), kind = "factor", optional = TRUE),
        group = list(label = tr("Colour by"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = utils::modifyList(chart_stat_defaults(),
                                   list(pairwise = TRUE)),
      controls = control
    ),
    stat_within = list(
      label = tr("Repeated measures (statistics)"),
      icon = "violin",
      group = "comparison",
      analysis = "repeated",
      description = tr(
        "Compare conditions measured on the same units (ggwithinstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        y = list(label = tr("Outcome (numeric)"), kind = "numeric"),
        x = list(label = tr("Conditions"), kind = "factor"),
        facet = list(label = tr("Facets"), kind = "factor", optional = TRUE),
        group = list(label = tr("Follow-up colour"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = utils::modifyList(chart_stat_defaults(),
                                   list(paired = TRUE)),
      controls = function(spec) {
        options <- utils::modifyList(chart_stat_defaults(),
                                     spec$options %||% list())
        chart_stat_controls(spec, htmltools::tagList(
          checkboxInput("chart_opt_paired", tr("Paired observations"),
                        value = isTRUE(options$paired))
        ))
      }
    ),
    stat_hist = list(
      label = tr("Distribution (statistics)"),
      icon = "histogram",
      group = "distribution",
      analysis = "univariate",
      description = tr(
        "Histogram with central tendency and effect size (gghistostats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        x = list(label = tr("Variable (numeric)"), kind = "numeric"),
        facet = list(label = tr("Facets"), kind = "factor", optional = TRUE)
      ),
      defaults = chart_stat_defaults(),
      controls = control
    ),
    stat_dot = list(
      label = tr("Ranked dot plot (statistics)"),
      icon = "dotplot",
      group = "distribution",
      analysis = "univariate",
      description = tr(
        "Dot plot of a ranked variable with a summary test (ggdotplotstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        x = list(label = tr("Variable (numeric)"), kind = "numeric"),
        y = list(label = tr("Labels"), kind = "any")
      ),
      defaults = chart_stat_defaults(),
      controls = control
    ),
    stat_scatter = list(
      label = tr("Correlation (statistics)"),
      icon = "scatter",
      group = "relationship",
      analysis = "relationship",
      description = tr(
        "Scatter plot with correlation and trend line (ggscatterstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        x = list(label = tr("X (numeric)"), kind = "numeric"),
        y = list(label = tr("Y (numeric)"), kind = "numeric"),
        facet = list(label = tr("Facets"), kind = "factor", optional = TRUE)
      ),
      defaults = chart_stat_defaults(),
      controls = control
    ),
    stat_corrmat = list(
      label = tr("Correlation matrix (statistics)"),
      icon = "heatmap",
      group = "relationship",
      analysis = "relationship",
      description = tr(
        "Correlation matrix of several variables (ggcorrmat)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        vars = list(label = tr("Variables (numeric)"), kind = "numeric",
                    multiple = TRUE, min = 2L),
        facet = list(label = tr("Facets"), kind = "factor", optional = TRUE)
      ),
      defaults = chart_stat_defaults(),
      controls = control
    ),
    stat_pie = list(
      label = tr("Proportions with test (statistics)"),
      icon = "pie",
      group = "composition",
      analysis = "categorical",
      description = tr(
        "Category proportions with a goodness-of-fit test (ggpiestats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        x = list(label = tr("Categories"), kind = "factor"),
        y = list(label = tr("Counts by"), kind = "factor", optional = TRUE)
      ),
      defaults = utils::modifyList(chart_stat_defaults(),
                                   list(pairwise = TRUE)),
      controls = control
    ),
    stat_bar = list(
      label = tr("Two-way table with test (statistics)"),
      icon = "bar",
      group = "comparison",
      analysis = "categorical",
      description = tr(
        "Bars for two categorical variables with a contingency test (ggbarstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        x = list(label = tr("Outcome categories"), kind = "factor"),
        y = list(label = tr("Groups"), kind = "factor")
      ),
      defaults = utils::modifyList(chart_stat_defaults(),
                                   list(pairwise = TRUE)),
      controls = control
    ),
    stat_coef = list(
      label = tr("Model coefficients (statistics)"),
      icon = "coef",
      group = "models",
      analysis = "models",
      description = tr(
        "Coefficient plot of a model estimated in the Models tab (ggcoefstats)."
      ),
      requires = "ggstatsplot",
      mapping = list(
        model = list(label = tr("Model"), kind = "model")
      ),
      defaults = chart_stat_defaults(),
      controls = function(spec) {
        chart_stat_controls(spec)
      }
    )
  )
}

#' Identifiers of the ggstatsplot types
#' @keywords internal
chart_stat_type_ids <- function() {
  names(chart_stat_types())
}

#' Whether a type is a ggstatsplot chart
#' @keywords internal
chart_stat_type <- function(type) {
  isTRUE(type %in% chart_stat_type_ids())
}

#' ggstatsplot object expression
#' @keywords internal
chart_stat_object <- function(spec) {
  type <- spec$type %||% ""
  dataset <- spec$dataset %||% "data"
  mapping <- spec$mapping %||% list()
  options <- utils::modifyList(chart_stat_defaults(),
                               spec$options %||% list())
  if (!is.null(options$paired) && isTRUE(options$paired)) {
    options$type <- "paired"
  }
  variable <- function(slot) {
    value <- mapping[[slot]] %||% character()
    value <- as.character(value)
    value[!is.na(value) & nzchar(value)]
  }
  one <- function(slot) {
    values <- variable(slot)
    if (length(values) == 0L) "" else values[[1L]]
  }
  facet <- one("facet")
  common_extras <- if (nzchar(facet)) {
    sprintf("grouped.by = %s", facet)
  } else {
    character()
  }

  args <- switch(
    type,
    stat_compare = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      sprintf("y = %s", one("y")),
      if (nzchar(one("group"))) sprintf("grouping.var = %s", one("group")),
      common_extras
    ),
    stat_within = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      sprintf("y = %s", one("y")),
      if (isTRUE(options$paired)) "paired = TRUE",
      if (nzchar(one("group"))) sprintf("grouping.var = %s", one("group")),
      common_extras
    ),
    stat_hist = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      if (nzchar(one("facet"))) sprintf("facet.by = %s", one("facet"))
    ),
    stat_dot = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      sprintf("y = %s", one("y"))
    ),
    stat_scatter = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      sprintf("y = %s", one("y")),
      common_extras
    ),
    stat_corrmat = c(
      sprintf("data = %s", dataset),
      sprintf("cor.vars = c(%s)", paste(variable("vars"), collapse = ", ")),
      if (nzchar(one("facet"))) sprintf("grouped.by = %s", one("facet"))
    ),
    stat_pie = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      if (nzchar(one("y"))) sprintf("y = %s", one("y"))
    ),
    stat_bar = c(
      sprintf("data = %s", dataset),
      sprintf("x = %s", one("x")),
      sprintf("y = %s", one("y"))
    ),
    stat_coef = sprintf("x = %s", one("model")),
    character()
  )
  if (length(args) == 0L) {
    stop("Unsupported statistical chart type.", call. = FALSE)
  }
  function_name <- switch(
    type,
    stat_compare = "ggbetweenstats",
    stat_within = "ggwithinstats",
    stat_hist = "gghistostats",
    stat_dot = "ggdotplotstats",
    stat_scatter = "ggscatterstats",
    stat_corrmat = "ggcorrmat",
    stat_pie = "ggpiestats",
    stat_bar = "ggbarstats",
    stat_coef = "ggcoefstats",
    NULL
  )
  if (is.null(function_name)) {
    stop("Unsupported statistical chart type.", call. = FALSE)
  }
  args <- c(args, chart_stat_common(spec, options))
  args <- args[nzchar(args)]
  sprintf("ggstatsplot::%s(%s)", function_name, paste(args, collapse = ", "))
}

#' Complete ggstatsplot command
#' @keywords internal
chart_stat_command <- function(spec) {
  sprintf("print(%s)", chart_stat_object(spec))
}
