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

#' Registry of extra chart types
#' @keywords internal
chart_types_extra <- function() {
  list(
    lollipop = chart_type_lollipop(),
    dumbbell = chart_type_dumbbell(),
    doughnut = chart_type_doughnut(),
    stacked_area = chart_type_stacked_area(),
    ridgeline = chart_type_ridgeline(),
    beeswarm = chart_type_beeswarm()
  )
}
