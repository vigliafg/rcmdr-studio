# Chart examples -------------------------------------------------------------
#
# A curated, offline gallery inspired by the R Graph Gallery.  An example is a
# chart recipe on a bundled sample data set: it can be rendered as a thumbnail,
# shown as code, or opened in the builder.  It never loads data into the user's
# session and never runs a command.

#' One entry of the example gallery
#' @keywords internal
chart_example_entry <- function(id, title, family, level, type, description,
                                data, data_name, data_code, mapping = list(),
                                options = list(), theme = list(),
                                labels = list(), source_url,
                                requires = character(), tags = character()) {
  list(
    id = id,
    title = title,
    family = family,
    level = level,
    type = type,
    description = description,
    data = data,
    data_name = data_name,
    data_code = data_code,
    mapping = mapping,
    options = options,
    theme = theme,
    labels = labels,
    source_url = source_url,
    requires = requires,
    tags = tags
  )
}

#' Data sets used by the examples
#'
#' Small, reproducible data frames.  The `*_code` strings are what the copied
#' example contains, so the snippet works in a fresh R session.
#' @keywords internal
chart_example_data_iris <- function() datasets::iris
#' @keywords internal
chart_example_data_tooth <- function() datasets::ToothGrowth
#' @keywords internal
chart_example_data_mtcars <- function() datasets::mtcars
#' @keywords internal
chart_example_data_mtcars_factors <- function() {
  within(datasets::mtcars, {
    cyl <- factor(cyl)
    gear <- factor(gear)
    am <- factor(am)
  })
}
#' @keywords internal
chart_example_data_faithful <- function() datasets::faithful
#' @keywords internal
chart_example_data_airquality <- function() datasets::airquality
#' @keywords internal
chart_example_data_usarrests_long <- function() {
  matrix <- as.data.frame(datasets::USArrests)
  data.frame(
    state = rownames(matrix),
    variable = rep(names(matrix), each = nrow(matrix)),
    value = as.vector(as.matrix(matrix)),
    stringsAsFactors = FALSE
  )
}
#' @keywords internal
chart_example_data_eu_stocks <- function() {
  series <- datasets::EuStockMarkets
  data.frame(
    time = as.numeric(stats::time(series)),
    as.data.frame(series)
  )
}

#' Means by cylinder count, for the lollipop example
#' @keywords internal
chart_example_data_means <- function() {
  table <- stats::aggregate(mpg ~ cyl, data = datasets::mtcars, FUN = mean)
  table$cyl <- factor(table$cyl)
  table
}

#' A small before/after table, for the dumbbell example
#' @keywords internal
chart_example_data_dumbbell <- function() {
  data.frame(
    category = c("Alpha", "Beta", "Gamma", "Delta"),
    start = c(18, 22, 15, 28),
    end = c(24, 20, 21, 33),
    stringsAsFactors = FALSE
  )
}

#' Species counts, for the doughnut example
#' @keywords internal
chart_example_data_species_counts <- function() {
  counts <- table(datasets::iris$Species)
  data.frame(
    category = names(counts),
    count = as.integer(counts),
    stringsAsFactors = FALSE
  )
}

#' Long stock series, for the stacked area example
#' @keywords internal
chart_example_data_stocks_long <- function() {
  series <- as.data.frame(datasets::EuStockMarkets)
  data.frame(
    time = rep(as.numeric(stats::time(datasets::EuStockMarkets)),
               ncol(series)),
    series = rep(names(series), each = nrow(series)),
    value = as.vector(as.matrix(series))
  )
}

#' Catalogue of chart examples
#' @keywords internal
chart_examples <- function() {
  examples <- list(
    # Distribution ---------------------------------------------------------
    chart_example_entry(
      "hist_basic", tr("Histogram"), "univariate", "basic", "histogram",
      tr("Distribution of a numeric variable with automatic bins."),
      data = chart_example_data_iris,
      data_name = "example_hist_basic", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length"),
      options = list(bins = 30),
      source_url = "https://r-graph-gallery.com/histogram.html",
      tags = c("distribution", "histogram")
    ),
    chart_example_entry(
      "hist_bins", tr("Histogram with fixed bins"), "univariate", "custom",
      "histogram",
      tr("A fixed number of bins makes two distributions comparable."),
      data = chart_example_data_iris,
      data_name = "example_hist_bins", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length"),
      options = list(bins = 15),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/histogram.html",
      tags = c("distribution", "histogram", "bins")
    ),
    chart_example_entry(
      "density_group", tr("Density by group"), "univariate", "basic",
      "density",
      tr("Smoothed distributions, one curve per group."),
      data = chart_example_data_iris,
      data_name = "example_density_group", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length", group = "Species"),
      options = list(adjust = 0.8),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/density-plot.html",
      tags = c("distribution", "density", "group")
    ),
    chart_example_entry(
      "violin_group", tr("Violin with box plot"), "comparison", "custom",
      "violin",
      tr("Distribution shape and quartiles in the same panel."),
      data = chart_example_data_tooth,
      data_name = "example_violin_group", data_code = "datasets::ToothGrowth",
      mapping = list(x = "len", group = "supp"),
      options = list(show_box = TRUE, scale = "area"),
      theme = list(ggplot_theme = "bw", palette = "tableau"),
      source_url = "https://r-graph-gallery.com/violin.html",
      tags = c("distribution", "violin", "box")
    ),
    chart_example_entry(
      "box_group", tr("Box plot by group"), "comparison", "basic", "boxplot",
      tr("Compare the spread of a numeric variable across groups."),
      data = chart_example_data_tooth,
      data_name = "example_box_group", data_code = "datasets::ToothGrowth",
      mapping = list(x = "len", group = "supp"),
      options = list(notch = FALSE, outline = TRUE),
      source_url = "https://r-graph-gallery.com/boxplot.html",
      tags = c("distribution", "boxplot", "group")
    ),
    chart_example_entry(
      "strip_group", tr("Strip chart"), "comparison", "basic", "strip",
      tr("Every observation, spread with jitter to avoid overplotting."),
      data = chart_example_data_iris,
      data_name = "example_strip_group", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length", group = "Species"),
      options = list(method = "jitter", jitter_width = 0.18,
                     jitter_height = 0.08),
      source_url = "https://r-graph-gallery.com/beeswarm.html",
      tags = c("distribution", "strip", "jitter")
    ),
    chart_example_entry(
      "ecdf_group", tr("Cumulative distribution"), "univariate", "basic",
      "ecdf",
      tr("Empirical cumulative distribution, one curve per group."),
      data = chart_example_data_iris,
      data_name = "example_ecdf_group", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length", group = "Species"),
      options = list(linetype = "solid"),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/ecdf.html",
      tags = c("distribution", "ecdf")
    ),
    # Relationship ---------------------------------------------------------
    chart_example_entry(
      "scatter_smooth", tr("Scatter with loess"), "relationship", "basic",
      "scatter",
      tr("Relationship between two numeric variables with a smooth trend."),
      data = chart_example_data_mtcars,
      data_name = "example_scatter_smooth", data_code = "datasets::mtcars",
      mapping = list(x = "wt", y = "mpg"),
      options = list(smooth = TRUE),
      source_url = "https://r-graph-gallery.com/scatterplot.html",
      tags = c("relationship", "scatter", "smooth")
    ),
    chart_example_entry(
      "scatter_group_ellipse", tr("Scatter by group with ellipse"),
      "relationship", "custom", "scatter",
      tr("Groups, colours and a confidence ellipse in one view."),
      data = chart_example_data_iris,
      data_name = "example_scatter_group_ellipse",
      data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length", y = "Sepal.Width",
                     group = "Species"),
      options = list(ellipse = TRUE),
      theme = list(palette = "tableau"),
      source_url = "https://r-graph-gallery.com/scatterplot.html",
      tags = c("relationship", "scatter", "ellipse")
    ),
    chart_example_entry(
      "density_2d", tr("2D density"), "relationship", "basic", "density_2d",
      tr("Contours of a two-dimensional density, with the points behind."),
      data = chart_example_data_faithful,
      data_name = "example_density_2d", data_code = "datasets::faithful",
      mapping = list(x = "eruptions", y = "waiting"),
      options = list(points = TRUE, bins = 8),
      source_url = "https://r-graph-gallery.com/2d-density-chart.html",
      tags = c("relationship", "density", "2d")
    ),
    chart_example_entry(
      "qq_norm", tr("Normal QQ plot"), "relationship", "basic", "qq",
      tr("Compare a numeric variable with a normal distribution."),
      data = chart_example_data_mtcars,
      data_name = "example_qq_norm", data_code = "datasets::mtcars",
      mapping = list(x = "mpg"),
      options = list(distribution = "norm", line = TRUE),
      source_url = "https://r-graph-gallery.com/qq-plot.html",
      tags = c("relationship", "qq", "distribution")
    ),
    chart_example_entry(
      "corr_mat", tr("Correlation matrix"), "relationship", "custom",
      "stat_corrmat",
      tr("Correlation matrix with the significance of each pair."),
      data = chart_example_data_mtcars,
      data_name = "example_corr_mat", data_code = "datasets::mtcars",
      mapping = list(vars = c("mpg", "disp", "hp", "wt", "qsec")),
      source_url = "https://r-graph-gallery.com/correlogram.html",
      requires = "ggstatsplot",
      tags = c("relationship", "correlation", "matrix")
    ),
    chart_example_entry(
      "heatmap_tile", tr("Tile heatmap"), "categorical", "custom",
      "heatmap",
      tr("A numeric value by two variables, with a sequential colour scale."),
      data = chart_example_data_usarrests_long,
      data_name = "example_heatmap_tile",
      data_code = paste0(
        "local({ m <- as.data.frame(datasets::USArrests); ",
        "data.frame(state = rownames(m), ",
        "variable = rep(names(m), each = nrow(m)), ",
        "value = as.vector(as.matrix(m))) })"
      ),
      mapping = list(x = "state", y = "variable", fill = "value"),
      options = list(show_values = FALSE, low = "#f7fbff",
                     high = "#08306b"),
      source_url = "https://r-graph-gallery.com/heatmap.html",
      tags = c("relationship", "heatmap", "tile")
    ),
    # Categorical ----------------------------------------------------------
    chart_example_entry(
      "bar_counts", tr("Counts by category"), "univariate", "basic", "bar",
      tr("Frequency of each level of a categorical variable."),
      data = chart_example_data_iris,
      data_name = "example_bar_counts", data_code = "datasets::iris",
      mapping = list(x = "Species"),
      options = list(bar_stat = "count"),
      source_url = "https://r-graph-gallery.com/barplot.html",
      tags = c("categorical", "bar", "counts")
    ),
    chart_example_entry(
      "bar_grouped", tr("Grouped bars"), "univariate", "custom", "bar",
      tr("Two categorical variables compared side by side."),
      data = chart_example_data_mtcars_factors,
      data_name = "example_bar_grouped",
      data_code = paste0(
        "within(datasets::mtcars, { cyl <- factor(cyl); ",
        "gear <- factor(gear) })"
      ),
      mapping = list(x = "cyl", group = "gear"),
      options = list(bar_stat = "count", position = "dodge"),
      theme = list(palette = "tableau"),
      source_url = "https://r-graph-gallery.com/stacked-barplot.html",
      tags = c("categorical", "bar", "group")
    ),
    chart_example_entry(
      "dot_rank", tr("Dot plot"), "univariate", "basic", "dot",
      tr("One dot per observation, stacked along a single axis."),
      data = chart_example_data_mtcars,
      data_name = "example_dot_rank", data_code = "datasets::mtcars",
      mapping = list(x = "mpg"),
      options = list(binaxis = "x", stackdir = "center"),
      source_url = "https://r-graph-gallery.com/dotplot.html",
      tags = c("categorical", "dot", "distribution")
    ),
    # Composition ----------------------------------------------------------
    chart_example_entry(
      "pie_share", tr("Proportions with test"), "categorical", "custom",
      "stat_pie",
      tr("Category proportions with a goodness-of-fit test."),
      data = chart_example_data_iris,
      data_name = "example_pie_share", data_code = "datasets::iris",
      mapping = list(x = "Species"),
      source_url = "https://r-graph-gallery.com/pie-plot.html",
      requires = "ggstatsplot",
      tags = c("composition", "pie", "proportion")
    ),
    # Evolution ------------------------------------------------------------
    chart_example_entry(
      "line_series", tr("Line over time"), "time", "basic", "line",
      tr("A numeric series over an ordered index."),
      data = chart_example_data_airquality,
      data_name = "example_line_series", data_code = "datasets::airquality",
      mapping = list(x = "Day", y = "Temp"),
      options = list(line_type = "line", linetype = "solid",
                     linewidth = 1),
      source_url = "https://r-graph-gallery.com/line-plot.html",
      tags = c("time", "line")
    ),
    chart_example_entry(
      "area_series", tr("Area chart"), "time", "custom", "line",
      tr("An area makes the magnitude of a single series easier to read."),
      data = chart_example_data_airquality,
      data_name = "example_area_series", data_code = "datasets::airquality",
      mapping = list(x = "Day", y = "Temp"),
      options = list(line_type = "area", linetype = "solid",
                     linewidth = 1),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/area-chart.html",
      tags = c("time", "area")
    ),
    chart_example_entry(
      "multi_line", tr("Multiple series"), "time", "custom", "line",
      tr("Several numeric series on the same time axis."),
      data = chart_example_data_eu_stocks,
      data_name = "example_multi_line",
      data_code = paste0(
        "local({ m <- datasets::EuStockMarkets; ",
        "data.frame(time = as.numeric(stats::time(m)), ",
        "as.data.frame(m)) })"
      ),
      mapping = list(x = "time", y = c("DAX", "SMI", "CAC", "FTSE")),
      options = list(line_type = "line", linetype = "solid",
                     linewidth = 0.9),
      theme = list(palette = "tableau"),
      source_url = "https://r-graph-gallery.com/time-series.html",
      tags = c("time", "line", "series")
    ),
    # Extra types ---------------------------------------------------------
    chart_example_entry(
      "lollipop_mean", tr("Mean by category"), "relationship", "custom",
      "lollipop",
      tr("A point and a stem per category: a compact ranking."),
      data = chart_example_data_means,
      data_name = "example_lollipop_mean",
      data_code = paste0(
        "local({ d <- stats::aggregate(mpg ~ cyl, data = datasets::mtcars, ",
        "FUN = mean); d$cyl <- factor(d$cyl); d })"
      ),
      mapping = list(x = "cyl", y = "mpg"),
      options = list(point_size = 4, line_width = 1.1),
      source_url = "https://r-graph-gallery.com/lollipop-plot.html",
      tags = c("categorical", "ranking", "lollipop")
    ),
    chart_example_entry(
      "dumbbell_change", tr("Before and after"), "comparison", "custom",
      "dumbbell",
      tr("Two values per category joined by a segment."),
      data = chart_example_data_dumbbell,
      data_name = "example_dumbbell_change",
      data_code = paste0(
        "data.frame(category = c(\"Alpha\", \"Beta\", \"Gamma\", \"Delta\"), ",
        "start = c(18, 22, 15, 28), end = c(24, 20, 21, 33))"
      ),
      mapping = list(x = "category", y = "start", y2 = "end"),
      options = list(point_size = 3.5, line_width = 1.2),
      source_url = "https://r-graph-gallery.com/dumbbell-plot.html",
      tags = c("comparison", "before-after", "dumbbell")
    ),
    chart_example_entry(
      "doughnut_share", tr("Species share"), "composition", "custom",
      "doughnut",
      tr("Part-to-whole proportions with a hole in the middle."),
      data = chart_example_data_species_counts,
      data_name = "example_doughnut_share",
      data_code = paste0(
        "local({ n <- table(datasets::iris$Species); ",
        "data.frame(category = names(n), count = as.integer(n)) })"
      ),
      mapping = list(x = "category", y = "count"),
      options = list(inner_radius = 0.55, width = 1),
      theme = list(palette = "tableau"),
      source_url = "https://r-graph-gallery.com/doughnut-plot.html",
      tags = c("composition", "doughnut", "share")
    ),
    chart_example_entry(
      "stacked_area_stocks", tr("Stacked stock series"), "time", "custom",
      "stacked_area",
      tr("Several series stacked over time, showing the total."),
      data = chart_example_data_stocks_long,
      data_name = "example_stacked_area_stocks",
      data_code = paste0(
        "local({ m <- datasets::EuStockMarkets; d <- as.data.frame(m); ",
        "data.frame(time = rep(as.numeric(stats::time(m)), ncol(d)), ",
        "series = rep(names(d), each = nrow(d)), ",
        "value = as.vector(as.matrix(d))) })"
      ),
      mapping = list(x = "time", y = "value", group = "series"),
      options = list(alpha = 0.75),
      theme = list(palette = "tableau"),
      source_url = "https://r-graph-gallery.com/stacked-area-graph.html",
      tags = c("time", "area", "stacked")
    ),
    chart_example_entry(
      "ridgeline_iris", tr("Ridgeline by species"), "univariate", "custom",
      "ridgeline",
      tr("Overlapping density curves, one per group."),
      data = chart_example_data_iris,
      data_name = "example_ridgeline_iris", data_code = "datasets::iris",
      mapping = list(x = "Sepal.Length", y = "Species"),
      options = list(scale = 1.4, alpha = 0.75),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/ridgeline-plot.html",
      requires = "ggridges",
      tags = c("distribution", "ridgeline", "density")
    ),
    chart_example_entry(
      "beeswarm_iris", tr("Beeswarm by species"), "univariate", "custom",
      "beeswarm",
      tr("Every observation packed without overlap."),
      data = chart_example_data_iris,
      data_name = "example_beeswarm_iris", data_code = "datasets::iris",
      mapping = list(x = "Species", y = "Sepal.Length"),
      options = list(point_size = 2, alpha = 0.8),
      theme = list(palette = "colorblind"),
      source_url = "https://r-graph-gallery.com/beeswarm.html",
      requires = "ggbeeswarm",
      tags = c("distribution", "beeswarm", "points")
    )
  )
  stats::setNames(examples, vapply(examples, function(example) example$id,
                                   character(1)))
}

#' One example by id
#' @keywords internal
chart_example <- function(id) {
  chart_examples()[[id %||% ""]]
}

#' Family choices for the example filters
#' @keywords internal
chart_example_families <- function() {
  families <- unique(vapply(chart_examples(), function(example) {
    example$family
  }, character(1)))
  labels <- vapply(families, chart_analysis_label, character(1))
  stats::setNames(
    c("all", families),
    c(tr("All families"), labels)
  )
}

#' Level choices for the example filters
#' @keywords internal
chart_example_levels <- function() {
  stats::setNames(
    c("all", "basic", "custom"),
    c(tr("All levels"), tr("Basic"), tr("Customised"))
  )
}

#' Whether an example can be rendered in this installation
#' @keywords internal
chart_example_available <- function(example) {
  if (is.null(example)) return(FALSE)
  chart_ext_available(example$requires) &&
    chart_type_available(example$type, "ggplot2")
}

#' Data frame of an example
#' @keywords internal
chart_example_data <- function(example) {
  if (is.null(example)) return(NULL)
  if (is.function(example$data)) example$data() else example$data
}

#' Specification of an example
#'
#' @param example An entry from [chart_examples()].
#' @param dataset Data set name or expression used in the command.
#' @keywords internal
chart_example_spec <- function(example, dataset = example$data_name) {
  if (is.null(example)) return(NULL)
  chart_spec(
    type = example$type,
    dataset = dataset,
    mapping = example$mapping,
    options = example$options,
    theme = example$theme,
    labels = example$labels
  )
}

#' Specification of an example on the active data set
#'
#' The mapping is carried over only when the columns exist and their kinds
#' match; otherwise the builder starts from the recipe and asks for variables.
#' @keywords internal
chart_example_spec_for_dataset <- function(example, state) {
  dataset <- active_dataset(state)
  mapping <- chart_example_mapping_for(example, state, dataset)
  chart_spec(
    type = example$type,
    dataset = dataset,
    mapping = mapping,
    options = example$options,
    theme = example$theme,
    labels = example$labels
  )
}

#' Code of an example, ready to copy
#' @keywords internal
chart_example_code <- function(example) {
  spec <- chart_example_spec(example, dataset = example$data_code)
  if (is.null(spec)) return("")
  tryCatch(chart_spec_command(spec),
           error = function(e) conditionMessage(e))
}

#' Mapping of an example on the active data set
#'
#' The recipe is portable only when the column names and their kinds match.
#' Otherwise the mapping stays empty and the builder asks the user to choose.
#' @keywords internal
chart_example_mapping_for <- function(example, state,
                                      dataset = active_dataset(state)) {
  if (is.null(example) || is.null(dataset)) return(list())
  df <- tryCatch(dataset(state), error = function(e) NULL)
  if (is.null(df)) return(list())
  info <- chart_type(example$type)
  slots <- if (is.null(info)) list() else info$mapping %||% list()
  mapping <- list()
  for (slot in names(example$mapping)) {
    value <- example$mapping[[slot]]
    if (is.null(value) || length(value) == 0L) next
    columns <- as.character(value)
    columns <- columns[nzchar(columns)]
    if (length(columns) == 0L || !all(columns %in% names(df))) return(list())
    kind <- slots[[slot]]$kind %||% "any"
    compatible <- switch(
      kind,
      numeric = all(vapply(columns, function(column) {
        is.numeric(df[[column]])
      }, logical(1))),
      factor = all(vapply(columns, function(column) {
        is.factor(df[[column]]) || is.logical(df[[column]]) ||
          is.character(df[[column]])
      }, logical(1))),
      any = TRUE,
      TRUE
    )
    if (!isTRUE(compatible)) return(list())
    mapping[[slot]] <- if (isTRUE(slots[[slot]]$multiple)) {
      columns
    } else {
      columns[[1L]]
    }
  }
  mapping
}

#' Table of examples for the gallery
#' @keywords internal
chart_example_table <- function(family = NULL, level = NULL, query = "") {
  examples <- chart_examples()
  rows <- lapply(examples, function(example) {
    data.frame(
      id = example$id,
      title = example$title,
      family = example$family,
      family_label = chart_analysis_label(example$family),
      level = example$level,
      level_label = if (identical(example$level, "custom")) {
        tr("Customised")
      } else {
        tr("Basic")
      },
      type = example$type,
      type_label = chart_type(example$type)$label %||% example$type,
      description = example$description,
      source_url = example$source_url,
      requires = paste(example$requires, collapse = ", "),
      installed = chart_example_available(example),
      thumbnail = chart_example_thumbnail(example$id),
      stringsAsFactors = FALSE
    )
  })
  table <- do.call(rbind, rows)
  table <- table[table$installed, , drop = FALSE]
  if (!is.null(family) && nzchar(family) && !identical(family, "all")) {
    table <- table[table$family == family, , drop = FALSE]
  }
  if (!is.null(level) && nzchar(level) && !identical(level, "all")) {
    table <- table[table$level == level, , drop = FALSE]
  }
  query <- trimws(query %||% "")
  if (nzchar(query)) {
    pattern <- tolower(query)
    hit <- grepl(pattern, tolower(table$title), fixed = TRUE) |
      grepl(pattern, tolower(table$description), fixed = TRUE) |
      grepl(pattern, tolower(table$family_label), fixed = TRUE) |
      grepl(pattern, tolower(table$type_label), fixed = TRUE)
    table <- table[hit, , drop = FALSE]
  }
  rownames(table) <- NULL
  table
}

#' Local thumbnail path of an example
#' @keywords internal
chart_example_thumbnail <- function(id) {
  sprintf("chart-examples/%s.png", id)
}
