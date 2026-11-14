# Chart type registry -------------------------------------------------------
#
# Each type knows the variables it needs, the controls it exposes, the command
# it produces and, when available, the plotly expression used for the
# interactive preview.  Every base command delegates to the builder used by the
# matching Rcmdr dialog, so the Chart Studio cannot drift from the dialog.

.chart_last_types <- NULL

#' Chart type identifiers
#' @keywords internal
chart_type_ids <- function() {
  c("histogram", "density", "boxplot", "scatter", "line", "bar", "dot",
    "strip", "qq", "means", "xyplot")
}

#' Chart type descriptor
#' @param type Type identifier.
#' @return A list describing the type, or `NULL`.
#' @keywords internal
chart_type <- function(type) {
  chart_types()[[type]]
}

#' Registry of chart types
#'
#' The registry is rebuilt on demand so translated labels follow the current
#' language and optional engines are discovered at runtime.
#' @keywords internal
chart_types <- function() {
  list(
    histogram = list(
      label = tr("Histogram"),
      icon = "hist",
      group = "distribution",
      description = tr("Distribution of a numeric variable."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(scale = "frequency", breaks = "Sturges", bins = 30L),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          radio_input(
            "chart_opt_scale", tr("Scale"),
            c("Frequency" = "frequency", "Density" = "density",
              "Percent" = "percent"),
            options$scale %||% "frequency"
          ),
          entry_input("chart_opt_breaks", tr("Breaks:"),
                      options$breaks %||% "Sturges"),
          spin_input("chart_opt_bins", tr("Bins (ggplot2 engine)"),
                     options$bins %||% 30L, min = 1, max = 200)
        )
      },
      command = function(spec) {
        cmd_histogram(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          spec$options$scale %||% "frequency",
          spec$options$breaks %||% "Sturges"
        )
      },
      interactive = function(spec) {
        plotly_code_histogram(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group)
        )
      },
      dialog = "Histogram",
      dialog_memory = function(spec) {
        list(
          variable = spec$mapping$x %||% "",
          group = spec$mapping$group %||% "",
          scale = spec$options$scale %||% "frequency",
          breaks = spec$options$breaks %||% "Sturges"
        )
      }
    ),
    density = list(
      label = tr("Density plot"),
      icon = "dens",
      group = "distribution",
      description = tr("Smoothed distribution of a numeric variable."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(bw = ""),
      controls = function(spec) {
        entry_input("chart_opt_bw", tr("Bandwidth (optional):"),
                    spec$options$bw %||% "")
      },
      command = function(spec) {
        cmd_density_plot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          spec$options$bw %||% ""
        )
      },
      dialog = "DensityPlot",
      dialog_memory = function(spec) {
        list(
          variable = spec$mapping$x %||% "",
          group = spec$mapping$group %||% "",
          bw = spec$options$bw %||% ""
        )
      }
    ),
    boxplot = list(
      label = tr("Boxplot"),
      icon = "box",
      group = "distribution",
      description = tr("Box-and-whisker plot of a numeric variable."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(),
      controls = function(spec) {
        help_text(tr("Without a group, one box for the selected variable."))
      },
      command = function(spec) {
        group <- chart_optional(spec$mapping$group)
        variable <- spec$mapping$x %||% ""
        cmd_boxplot(
          spec$dataset, variable,
          response = if (is.null(group)) NULL else variable,
          group = group
        )
      },
      interactive = function(spec) {
        group <- chart_optional(spec$mapping$group)
        variable <- spec$mapping$x %||% ""
        plotly_code_boxplot(
          spec$dataset, variable,
          response = if (is.null(group)) NULL else variable,
          group = group
        )
      },
      dialog = "boxPlot",
      dialog_memory = function(spec) {
        group <- spec$mapping$group %||% ""
        list(
          variables = spec$mapping$x %||% "",
          response = if (nzchar(group)) spec$mapping$x %||% "" else "",
          group = group
        )
      }
    ),
    scatter = list(
      label = tr("Scatterplot"),
      icon = "scat",
      group = "relationship",
      description = tr("Relationship between two numeric variables."),
      mapping = list(
        x = list(label = tr("Horizontal axis (pick one)"), kind = "numeric"),
        y = list(label = tr("Vertical axis (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(smooth = FALSE, boxplots = FALSE, log = ""),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_smooth", tr("Least-squares line"),
                         options$smooth),
          checkbox_input("chart_opt_boxplots", tr("Marginal boxplots"),
                         options$boxplots),
          radio_input(
            "chart_opt_log", tr("Log axes"),
            c("None" = "", "x" = "x", "y" = "y", "xy" = "xy"),
            options$log %||% ""
          )
        )
      },
      command = function(spec) {
        cmd_scatterplot(
          spec$dataset, spec$mapping$x %||% "", spec$mapping$y %||% "",
          chart_optional(spec$mapping$group),
          isTRUE(spec$options$smooth),
          isTRUE(spec$options$boxplots),
          spec$options$log %||% ""
        )
      },
      interactive = function(spec) {
        plotly_code_scatter(
          spec$dataset, spec$mapping$x %||% "", spec$mapping$y %||% "",
          chart_optional(spec$mapping$group),
          isTRUE(spec$options$smooth),
          spec$options$log %||% ""
        )
      },
      dialog = "scatterPlot",
      dialog_memory = function(spec) {
        list(
          x = spec$mapping$x %||% "",
          y = spec$mapping$y %||% "",
          group = spec$mapping$group %||% "",
          smooth = isTRUE(spec$options$smooth),
          boxplots = isTRUE(spec$options$boxplots),
          log = spec$options$log %||% ""
        )
      }
    ),
    line = list(
      label = tr("Line graph"),
      icon = "line",
      group = "relationship",
      description = tr("One or more numeric series over an index variable."),
      mapping = list(
        x = list(label = tr("X variable (pick one)"), kind = "any"),
        y = list(label = tr("Y variable(s) (pick one or more)"),
                 kind = "numeric", multiple = TRUE)
      ),
      defaults = list(),
      controls = function(spec) {
        help_text(tr("Each selected numeric variable becomes one line."))
      },
      command = function(spec) {
        cmd_lineplot(
          spec$dataset, spec$mapping$x %||% "",
          as.character(spec$mapping$y %||% character())
        )
      },
      interactive = function(spec) {
        plotly_code_line(
          spec$dataset, spec$mapping$x %||% "",
          as.character(spec$mapping$y %||% character())
        )
      },
      dialog = "linePlot",
      dialog_memory = function(spec) {
        list(x = spec$mapping$x %||% "",
             y = as.character(spec$mapping$y %||% character()))
      }
    ),
    bar = list(
      label = tr("Bar graph"),
      icon = "bar",
      group = "categorical",
      description = tr("Counts of a categorical variable."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "factor"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(),
      controls = function(spec) {
        help_text(tr("Use a factor for the bars, or convert the variable first."))
      },
      command = function(spec) {
        cmd_barplot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group)
        )
      },
      dialog = "barGraph",
      dialog_memory = function(spec) {
        list(variable = spec$mapping$x %||% "",
             group = spec$mapping$group %||% "")
      }
    ),
    dot = list(
      label = tr("Dot plot"),
      icon = "dot",
      group = "distribution",
      description = tr("Dot plot of a numeric variable."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(),
      controls = function(spec) help_text(tr("One dot per observation.")),
      command = function(spec) {
        cmd_dotplot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group)
        )
      },
      dialog = "DotPlot",
      dialog_memory = function(spec) {
        list(variable = spec$mapping$x %||% "",
             group = spec$mapping$group %||% "")
      }
    ),
    strip = list(
      label = tr("Strip chart"),
      icon = "strip",
      group = "distribution",
      description = tr("One-dimensional scatter of a numeric variable."),
      mapping = list(
        x = list(label = tr("Response variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(method = "stack"),
      controls = function(spec) {
        radio_input(
          "chart_opt_method", tr("Method"),
          c("Stack" = "stack", "Jitter" = "jitter"),
          spec$options$method %||% "stack"
        )
      },
      command = function(spec) {
        cmd_stripchart(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          spec$options$method %||% "stack"
        )
      },
      dialog = "stripChart",
      dialog_memory = function(spec) {
        list(response = spec$mapping$x %||% "",
             group = spec$mapping$group %||% "",
             method = spec$options$method %||% "stack")
      }
    ),
    qq = list(
      label = tr("Quantile-comparison plot"),
      icon = "qq",
      group = "diagnostic",
      description = tr("Compare a numeric variable with a theoretical distribution."),
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(),
      controls = function(spec) help_text(tr("Uses the Rcmdr qqPlot defaults.")),
      command = function(spec) {
        cmd_qqplot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group)
        )
      },
      dialog = "QQPlot",
      dialog_memory = function(spec) {
        list(variable = spec$mapping$x %||% "",
             group = spec$mapping$group %||% "")
      }
    ),
    means = list(
      label = tr("Plot of means"),
      icon = "means",
      group = "relationship",
      description = tr("Mean of a response variable by factor level."),
      mapping = list(
        x = list(label = tr("Response variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Factor (pick one)"), kind = "factor")
      ),
      defaults = list(error_bars = "se", legend = TRUE),
      controls = function(spec) {
        htmltools::tagList(
          radio_input(
            "chart_opt_error_bars", tr("Error bars"),
            c("Standard error" = "se", "Standard deviation" = "sd",
              "Confidence interval" = "ci"),
            spec$options$error_bars %||% "se"
          ),
          checkbox_input("chart_opt_legend", tr("Show legend"),
                         isTRUE(spec$options$legend %||% TRUE))
        )
      },
      command = function(spec) {
        cmd_plot_means(
          spec$dataset, spec$mapping$x %||% "",
          spec$mapping$group %||% "",
          spec$options$error_bars %||% "se",
          isTRUE(spec$options$legend %||% TRUE)
        )
      },
      dialog = "PlotMeans",
      dialog_memory = function(spec) {
        list(response = spec$mapping$x %||% "",
             group = spec$mapping$group %||% "",
             error_bars = spec$options$error_bars %||% "se",
             legend = isTRUE(spec$options$legend %||% TRUE))
      }
    ),
    xyplot = list(
      label = tr("XY conditioning plot"),
      icon = "xy",
      group = "relationship",
      description = tr("Lattice plot of y against x, conditioned on a factor."),
      mapping = list(
        x = list(label = tr("X variable (pick one)"), kind = "any"),
        y = list(label = tr("Y variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Conditioning factor (optional)"),
                     kind = "factor", optional = TRUE)
      ),
      defaults = list(type = "p", layout = ""),
      controls = function(spec) {
        htmltools::tagList(
          radio_input(
            "chart_opt_type", tr("Plot type"),
            c("Points" = "p", "Lines" = "l", "Both" = "b"),
            spec$options$type %||% "p"
          ),
          entry_input("chart_opt_layout", tr("Layout (e.g. 2,2):"),
                      spec$options$layout %||% "")
        )
      },
      command = function(spec) {
        cmd_xyplot(
          spec$dataset, spec$mapping$x %||% "", spec$mapping$y %||% "",
          chart_optional(spec$mapping$group),
          spec$options$type %||% "p",
          spec$options$layout %||% ""
        )
      },
      dialog = "Xyplot",
      dialog_memory = function(spec) {
        list(x = spec$mapping$x %||% "",
             y = spec$mapping$y %||% "",
             group = spec$mapping$group %||% "",
             type = spec$options$type %||% "p",
             layout = spec$options$layout %||% "")
      }
    )
  )
}

#' Normalise an optional mapping value
#' @keywords internal
chart_optional <- function(value) {
  if (is.null(value) || length(value) == 0L) return(NULL)
  value <- as.character(value)[[1L]]
  if (!nzchar(value)) NULL else value
}

#' Choices for a mapping slot
#' @keywords internal
chart_mapping_choices <- function(state, rule) {
  kind <- rule$kind %||% "any"
  variables <- switch(
    kind,
    numeric = numeric_variables(state),
    factor = factor_variables(state),
    any = variables(state),
    variables(state)
  )
  variables %||% character()
}

#' Controls for the mappings of a chart type
#' @keywords internals
chart_mapping_controls <- function(state, spec, pending = NULL) {
  info <- chart_type(spec$type)
  if (is.null(info)) return(NULL)
  values <- spec$mapping %||% list()
  if (!is.null(pending) && identical(pending$type, spec$type) &&
      identical(pending$dataset, spec$dataset)) {
    values <- utils::modifyList(values, pending$mapping %||% list())
  }

  controls <- lapply(names(info$mapping), function(slot) {
    rule <- info$mapping[[slot]]
    choices <- chart_mapping_choices(state, rule)
    value <- values[[slot]]
    if (isTRUE(rule$optional) && !isTRUE(rule$multiple)) {
      choices <- c(stats::setNames("", tr("<none>")),
                   stats::setNames(choices, choices))
      selected <- chart_optional(value) %||% ""
    } else {
      choices <- stats::setNames(choices, choices)
      selected <- as.character(value %||% character())
      selected <- selected[selected %in% unname(choices)]
      if (isTRUE(rule$multiple)) {
        if (length(selected) == 0L && length(choices) > 0L) {
          selected <- unname(choices)[[1L]]
        }
      } else {
        if (length(selected) == 0L && length(choices) > 0L) {
          selected <- unname(choices)[[1L]]
        }
        selected <- selected[[1L]]
      }
    }
    selectizeInput(
      paste0("chart_map_", slot), rule$label %||% slot,
      choices = choices,
      selected = selected,
      multiple = isTRUE(rule$multiple),
      width = "100%"
    )
  })
  htmltools::tagList(controls)
}

#' Available chart types by family
#' @keywords internal
chart_type_choices <- function() {
  types <- chart_types()
  labels <- vapply(types, function(info) info$label, character(1))
  stats::setNames(names(types), unname(labels))
}
