# Extra chart types ---------------------------------------------------------
#
# Types that are reproducible with ggplot2 alone, or with a small optional
# package already used by the gallery.  They declare `engines = "ggplot2"`, so
# the builder never offers them through the legacy base engine.

#' Lollipop chart
#' @keywords internal
chart_type_lollipop <- function() {
  list(
    label = tr("Lollipop chart"),
    icon = "dot",
    group = "relationship",
    analysis = "relationship",
    description = tr(
      "A point per category on a stem: a compact ranking or comparison."
    ),
    engines = "ggplot2",
    mapping = list(
      x = list(label = tr("Category (pick one)"), kind = "any"),
      y = list(label = tr("Value (pick one)"), kind = "numeric")
    ),
    defaults = list(point_size = 3, line_width = 1),
    option_groups = list(
      Points = c("point_size"),
      Lines = c("line_width")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_point_size", tr("Point size"),
                     options$point_size %||% 3, min = 0.5, step = 0.5),
        number_input("chart_opt_line_width", tr("Stem width"),
                     options$line_width %||% 1, min = 0.1, step = 0.1)
      )
    }
  )
}

#' Dumbbell chart
#' @keywords internal
chart_type_dumbbell <- function() {
  list(
    label = tr("Dumbbell chart"),
    icon = "dot",
    group = "comparison",
    analysis = "comparison",
    description = tr(
      "Two values per category joined by a segment: a before/after comparison."
    ),
    engines = "ggplot2",
    mapping = list(
      x = list(label = tr("Category (pick one)"), kind = "any"),
      y = list(label = tr("Start value (pick one)"), kind = "numeric"),
      y2 = list(label = tr("End value (pick one)"), kind = "numeric")
    ),
    defaults = list(point_size = 3, line_width = 1),
    option_groups = list(
      Points = c("point_size"),
      Lines = c("line_width")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_point_size", tr("Point size"),
                     options$point_size %||% 3, min = 0.5, step = 0.5),
        number_input("chart_opt_line_width", tr("Segment width"),
                     options$line_width %||% 1, min = 0.1, step = 0.1)
      )
    }
  )
}

#' Doughnut chart
#' @keywords internal
chart_type_doughnut <- function() {
  list(
    label = tr("Doughnut chart"),
    icon = "pie",
    group = "composition",
    analysis = "composition",
    description = tr(
      "Part-to-whole proportions with a hole in the middle."
    ),
    engines = "ggplot2",
    mapping = list(
      x = list(label = tr("Category (pick one)"), kind = "factor"),
      y = list(label = tr("Value (pick one)"), kind = "numeric")
    ),
    defaults = list(inner_radius = 0.5, width = 1),
    option_groups = list(
      Ring = c("inner_radius", "width")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_inner_radius", tr("Hole (0-0.9)"),
                     options$inner_radius %||% 0.5, min = 0, max = 0.9,
                     step = 0.05),
        number_input("chart_opt_width", tr("Ring width"),
                     options$width %||% 1, min = 0.1, step = 0.1)
      )
    }
  )
}

#' Stacked area chart
#' @keywords internal
chart_type_stacked_area <- function() {
  list(
    label = tr("Stacked area chart"),
    icon = "area",
    group = "time",
    analysis = "time",
    description = tr(
      "Several series stacked over an ordered index, showing the total."
    ),
    engines = "ggplot2",
    mapping = list(
      x = list(label = tr("X variable (pick one)"), kind = "any"),
      y = list(label = tr("Value (pick one)"), kind = "numeric"),
      group = list(label = tr("Series (pick one)"), kind = "factor")
    ),
    defaults = list(alpha = 0.8),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        slider_input("chart_opt_alpha", tr("Alpha"), 0, 1,
                     options$alpha %||% 0.8, 0.05)
      )
    }
  )
}

#' Ridgeline chart
#' @keywords internal
chart_type_ridgeline <- function() {
  list(
    label = tr("Ridgeline chart"),
    icon = "density",
    group = "distribution",
    analysis = "univariate",
    description = tr(
      "Overlapping density curves, one per group (ggridges)."
    ),
    engines = "ggplot2",
    requires = "ggridges",
    mapping = list(
      x = list(label = tr("Variable (pick one)"), kind = "numeric"),
      y = list(label = tr("Group (pick one)"), kind = "factor")
    ),
    defaults = list(scale = 1.5, alpha = 0.8),
    option_groups = list(
      Shape = c("scale", "alpha")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_scale", tr("Overlap scale"),
                     options$scale %||% 1.5, min = 0.2, step = 0.1),
        slider_input("chart_opt_alpha", tr("Alpha"), 0, 1,
                     options$alpha %||% 0.8, 0.05)
      )
    }
  )
}

#' Beeswarm chart
#' @keywords internal
chart_type_beeswarm <- function() {
  list(
    label = tr("Beeswarm chart"),
    icon = "strip",
    group = "distribution",
    analysis = "univariate",
    description = tr(
      "Every observation, packed without overlap (ggbeeswarm)."
    ),
    engines = "ggplot2",
    requires = "ggbeeswarm",
    mapping = list(
      x = list(label = tr("Group (pick one)"), kind = "factor"),
      y = list(label = tr("Variable (pick one)"), kind = "numeric"),
      group = list(label = tr("Colour by (optional)"), kind = "factor",
                   optional = TRUE)
    ),
    defaults = list(point_size = 2, alpha = 0.8),
    option_groups = list(
      Points = c("point_size", "alpha")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_point_size", tr("Point size"),
                     options$point_size %||% 2, min = 0.2, step = 0.2),
        slider_input("chart_opt_alpha", tr("Alpha"), 0, 1,
                     options$alpha %||% 0.8, 0.05)
      )
    }
  )
}

#' Radar chart
#' @keywords internal
chart_type_radar <- function() {
  list(
    label = tr("Radar chart"),
    icon = "line",
    group = "comparison",
    analysis = "comparison",
    description = tr(
      "A closed profile across categories, optionally one profile per group."
    ),
    engines = "ggplot2",
    mapping = list(
      x = list(label = tr("Category (pick one)"), kind = "factor"),
      y = list(label = tr("Value (pick one)"), kind = "numeric"),
      group = list(label = tr("Profile (optional)"), kind = "factor",
                   optional = TRUE)
    ),
    defaults = list(point_size = 2, line_width = 1, alpha = 0.25),
    option_groups = list(
      Points = c("point_size"),
      Lines = c("line_width"),
      Area = c("alpha")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        number_input("chart_opt_point_size", tr("Point size"),
                     options$point_size %||% 2, min = 0.2, step = 0.2),
        number_input("chart_opt_line_width", tr("Line width"),
                     options$line_width %||% 1, min = 0.1, step = 0.1),
        slider_input("chart_opt_alpha", tr("Area alpha"), 0, 1,
                     options$alpha %||% 0.25, 0.05)
      )
    },
    code = function(spec) chart_radar_command(spec)
  )
}

#' Parallel coordinates chart
#' @keywords internal
chart_type_parallel <- function() {
  list(
    label = tr("Parallel coordinates"),
    icon = "line",
    group = "relationship",
    analysis = "relationship",
    description = tr(
      "Several numeric variables compared across rows (GGally)."
    ),
    engines = "ggplot2",
    requires = "GGally",
    mapping = list(
      vars = list(label = tr("Variables (numeric)"), kind = "numeric",
                  multiple = TRUE, min = 2L),
      group = list(label = tr("Colour by (optional)"), kind = "factor",
                   optional = TRUE)
    ),
    defaults = list(alpha = 0.5, scale = "std"),
    option_groups = list(
      Lines = c("alpha", "scale")
    ),
    controls = function(spec) {
      options <- spec$options %||% list()
      htmltools::tagList(
        slider_input("chart_opt_alpha", tr("Line alpha"), 0, 1,
                     options$alpha %||% 0.5, 0.05),
        selectInput(
          "chart_opt_scale", tr("Scale"),
          choices = stats::setNames(
            c("std", "center", "scale", "uniminmax", "globalminmax"),
            c("Standardise", "Center", "Scale", "Unit interval",
              "Global min-max")
          ),
          selected = options$scale %||% "std"
        )
      )
    },
    code = function(spec) chart_parallel_command(spec)
  )
}

#' Registry of extra chart types
#' @keywords internal
chart_types_extra <- function() {
  list(
    lollipop = chart_type_lollipop(),
    dumbbell = chart_type_dumbbell(),
    doughnut = chart_type_doughnut(),
    stacked_area = chart_type_stacked_area(),
    ridgeline = chart_type_ridgeline(),
    beeswarm = chart_type_beeswarm(),
    radar = chart_type_radar(),
    parallel = chart_type_parallel()
  )
}


#' Code of a radar chart
#'
#' The categories are ordered and the first row is repeated per group, so the
#' polygon closes.  The code stays a single ggplot expression inside `local()`,
#' which makes it reproducible outside the app.
#' @keywords internal
chart_radar_command <- function(spec) {
  mapping <- spec$mapping %||% list()
  x <- chart_gg_optional(mapping$x)
  y <- chart_gg_optional(mapping$y)
  group <- chart_gg_optional(mapping$group)
  options <- utils::modifyList(chart_ggplot_option_defaults(),
                               spec$options %||% list())
  alpha <- chart_gg_number(options$alpha %||% 0.25, default = 0.25,
                           min = 0, max = 1)
  point_size <- chart_gg_number(options$point_size %||% 2,
                                default = 2, min = 0.2)
  line_width <- chart_gg_number(options$line_width %||% 1,
                                default = 1, min = 0.1)
  palette <- chart_gg_palette(spec)
  group_code <- if (nzchar(group)) {
    sprintf("factor(d[[%s]])", chart_quote(group))
  } else {
    "factor(\"All\")"
  }
  scales <- character()
  if (!is.null(palette)) {
    fill_scale <- chart_gg_manual_scale("fill", palette)
    colour_scale <- chart_gg_manual_scale("colour", palette)
    if (!is.null(fill_scale)) scales <- c(scales, fill_scale)
    if (!is.null(colour_scale)) scales <- c(scales, colour_scale)
  }
  pieces <- c(
    sprintf("ggplot2::geom_polygon(alpha = %s)", format(alpha, digits = 3)),
    sprintf("ggplot2::geom_path(linewidth = %s)",
            format(line_width, digits = 3)),
    sprintf("ggplot2::geom_point(size = %s)",
            format(point_size, digits = 3)),
    "ggplot2::scale_x_continuous(limits = c(1, length(levels(d$.category)) + 1), breaks = seq_along(levels(d$.category)), labels = levels(d$.category))",
    "ggplot2::coord_polar()",
    scales,
    chart_gg_theme(spec),
    "ggplot2::theme(axis.title = ggplot2::element_blank(), axis.text.y = ggplot2::element_blank(), axis.ticks.y = ggplot2::element_blank())",
    chart_gg_labs(spec)
  )
  pieces <- pieces[nzchar(pieces)]
  sprintf(
    paste0(
      "local({ d <- %s; d$.category <- factor(d[[%s]]); ",
      "d$.group <- %s; d$.position <- as.numeric(d$.category); ",
      "d <- d[order(d$.group, d$.position), , drop = FALSE]; ",
      "d <- do.call(rbind, lapply(split(d, d$.group), function(z) ",
      "{ close <- z[1, , drop = FALSE]; ",
      "close$.position <- max(z$.position) + 1; rbind(z, close) })); ",
      "print(ggplot2::ggplot(d, ggplot2::aes(x = .position, y = %s, ",
      "group = .group, fill = .group, colour = .group)) + %s) })"
    ),
    spec$dataset %||% "", chart_quote(x), group_code, y,
    paste(pieces, collapse = " + ")
  )
}

#' Code of a parallel coordinates chart
#' @keywords internal
chart_parallel_command <- function(spec) {
  mapping <- spec$mapping %||% list()
  vars <- as.character(mapping$vars %||% character())
  vars <- vars[nzchar(vars)]
  group <- chart_gg_optional(mapping$group)
  options <- utils::modifyList(chart_ggplot_option_defaults(),
                               spec$options %||% list())
  alpha <- chart_gg_number(options$alpha %||% 0.5, default = 0.5,
                           min = 0, max = 1)
  scale <- options$scale %||% "std"
  if (!scale %in% c("std", "center", "scale", "uniminmax",
                    "globalminmax")) {
    scale <- "std"
  }
  columns <- paste(chart_quote(vars), collapse = ", ")
  group_arg <- if (nzchar(group)) {
    sprintf(", groupColumn = %s", chart_quote(group))
  } else {
    ""
  }
  sprintf(
    paste0(
      "local({ d <- %s; print(GGally::ggparcoord(d, ",
      "columns = match(c(%s), names(d))%s, alphaLines = %s, ",
      "scale = %s)) })"
    ),
    spec$dataset %||% "", columns, group_arg,
    format(alpha, digits = 3), chart_quote(scale)
  )
}
