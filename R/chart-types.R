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
    "strip", "qq", "means", "xyplot", "violin", "ecdf", "density_2d",
    "heatmap", names(chart_compose_types()), chart_stat_type_ids())
}

#' Engines supported by a chart type
#' @keywords internal
chart_type_engines <- function(info) {
  engines <- info$engines %||% c("base", "ggplot2")
  engines <- as.character(engines)
  engines[nzchar(engines)]
}

#' Whether a chart type is available
#'
#' A type is available when the engine supports it and the optional package it
#' needs is installed.  Chart types that need an extension are therefore simply
#' absent from the selectors instead of failing at render time.
#' @keywords internal
chart_type_available <- function(id, engine = "ggplot2") {
  info <- chart_type(id)
  if (is.null(info)) return(FALSE)
  if (!is.null(engine) && !engine %in% chart_type_engines(info)) return(FALSE)
  chart_ext_available(info$requires)
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
#' language and optional extensions are discovered at runtime.
#' @keywords internal
chart_types_builtin <- function() {
  core <- chart_types_core()
  stat <- lapply(chart_stat_types(), function(info) {
    info$engines <- "ggplot2"
    info$code <- chart_stat_command
    info
  })
  compose <- lapply(chart_compose_types(), function(info) {
    info$engines <- "ggplot2"
    info$code <- chart_compose_command
    info
  })
  c(core, stat, compose)
}

#' Core chart types (built-in ggplot2 charts)
#' @keywords internal
chart_types_core <- function() {
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
      defaults = list(bw = "", kernel = "", adjust = 0, rug = FALSE,
                      grid = FALSE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          entry_input("chart_opt_bw", tr("Bandwidth (optional):"),
                      options$bw %||% ""),
          selectInput(
            "chart_opt_kernel", tr("Kernel"),
            choices = stats::setNames(
              c("", "gaussian", "epanechnikov", "rectangular", "triangular"),
              c(tr("Default"), "Gaussian", "Epanechnikov", "Rectangular",
                "Triangular")
            ),
            selected = options$kernel %||% ""
          ),
          spin_input("chart_opt_adjust", tr("Adjust (0 = auto)"),
                     options$adjust %||% 0, min = 0, step = 0.1),
          checkbox_input("chart_opt_rug", tr("Rug"), isTRUE(options$rug)),
          checkbox_input("chart_opt_grid", tr("Grid"), isTRUE(options$grid))
        )
      },
      command = function(spec) {
        options <- spec$options %||% list()
        cmd_density_plot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          options$bw %||% "",
          kernel = options$kernel %||% "",
          adjust = options$adjust %||% 0,
          rug = isTRUE(options$rug),
          grid = isTRUE(options$grid)
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
      defaults = list(notch = FALSE, notchwidth = 0.5, varwidth = FALSE,
                      horizontal = FALSE, outline = TRUE, width = 0),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_notch", tr("Notched box"),
                         isTRUE(options$notch)),
          spin_input("chart_opt_notchwidth", tr("Notch width"),
                     options$notchwidth %||% 0.5, min = 0, max = 1,
                     step = 0.05),
          checkbox_input("chart_opt_varwidth", tr("Width by group size"),
                         isTRUE(options$varwidth)),
          checkbox_input("chart_opt_horizontal", tr("Horizontal"),
                         isTRUE(options$horizontal)),
          checkbox_input("chart_opt_outline", tr("Show outliers"),
                         isTRUE(options$outline %||% TRUE)),
          spin_input("chart_opt_width", tr("Box width (0 = auto)"),
                     options$width %||% 0, min = 0, step = 0.1)
        )
      },
      command = function(spec) {
        options <- spec$options %||% list()
        group <- chart_optional(spec$mapping$group)
        variable <- spec$mapping$x %||% ""
        cmd_boxplot(
          spec$dataset, variable,
          response = if (is.null(group)) NULL else variable,
          group = group,
          notch = isTRUE(options$notch),
          notchwidth = options$notchwidth %||% 0.5,
          varwidth = isTRUE(options$varwidth),
          horizontal = isTRUE(options$horizontal),
          outline = !isFALSE(options$outline %||% TRUE),
          width = options$width %||% 0
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
      defaults = list(smooth = FALSE, boxplots = FALSE, log = "",
                      regression = FALSE, ellipse = FALSE, grid = FALSE,
                      jitter = 0),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_smooth", tr("Loess smooth"),
                         options$smooth),
          checkbox_input("chart_opt_regression", tr("Regression line"),
                         options$regression),
          checkbox_input("chart_opt_ellipse", tr("Confidence ellipse"),
                         options$ellipse),
          checkbox_input("chart_opt_boxplots", tr("Marginal boxplots"),
                         options$boxplots),
          checkbox_input("chart_opt_grid", tr("Grid"), options$grid),
          spin_input("chart_opt_jitter", tr("Jitter (0 = off)"),
                     options$jitter %||% 0, min = 0, step = 0.02),
          radio_input(
            "chart_opt_log", tr("Log axes"),
            c("None" = "", "x" = "x", "y" = "y", "xy" = "xy"),
            options$log %||% ""
          )
        )
      },
      command = function(spec) {
        options <- spec$options %||% list()
        cmd_scatterplot(
          spec$dataset, spec$mapping$x %||% "", spec$mapping$y %||% "",
          chart_optional(spec$mapping$group),
          isTRUE(options$smooth),
          isTRUE(options$boxplots),
          options$log %||% "",
          regression = isTRUE(options$regression),
          ellipse = isTRUE(options$ellipse),
          grid = isTRUE(options$grid),
          jitter = options$jitter %||% 0
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
                 kind = "numeric", multiple = TRUE),
        group = list(label = tr("Groups (optional, ggplot2)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(line_type = "line", linetype = "solid", linewidth = 1),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          selectInput(
            "chart_opt_line_type", tr("Line type (ggplot2)"),
            choices = stats::setNames(
              c("line", "step", "area"),
              c(tr("Line"), tr("Step"), tr("Area"))
            ),
            selected = options$line_type %||% "line"
          ),
          selectInput(
            "chart_opt_linetype", tr("Line style"),
            choices = stats::setNames(
              c("solid", "dashed", "dotted", "longdash"),
              c(tr("Solid"), tr("Dashed"), tr("Dotted"), tr("Long dash"))
            ),
            selected = options$linetype %||% "solid"
          ),
          spin_input("chart_opt_linewidth", tr("Line width"),
                     options$linewidth %||% 1, min = 0.1, step = 0.1),
          help_text(tr("Each selected numeric variable becomes one line."))
        )
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
      defaults = list(width = 0, bar_stat = "count"),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          spin_input("chart_opt_width", tr("Bar width (0 = auto)"),
                     options$width %||% 0, min = 0, step = 0.1),
          selectInput(
            "chart_opt_bar_stat", tr("Statistic (ggplot2)"),
            choices = stats::setNames(
              c("count", "percent"),
              c(tr("Counts"), tr("Percent"))
            ),
            selected = options$bar_stat %||% "count"
          ),
          help_text(tr("Use a factor for the bars, or convert the variable first."))
        )
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
      defaults = list(bin = FALSE, binaxis = "x", stackdir = "center",
                      dotsize = 1, binwidth = 0),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_bin", tr("Binned (base engine)"),
                         isTRUE(options$bin)),
          selectInput(
            "chart_opt_binaxis", tr("Bin axis (ggplot2)"),
            choices = stats::setNames(c("x", "y"), c("X", "Y")),
            selected = options$binaxis %||% "x"
          ),
          selectInput(
            "chart_opt_stackdir", tr("Stack direction (ggplot2)"),
            choices = stats::setNames(
              c("up", "down", "center", "centerwhole"),
              c("Up", "Down", "Center", "Center whole")
            ),
            selected = options$stackdir %||% "center"
          ),
          spin_input("chart_opt_dotsize", tr("Dot size"),
                     options$dotsize %||% 1, min = 0.1, step = 0.1),
          spin_input("chart_opt_binwidth", tr("Bin width (0 = auto)"),
                     options$binwidth %||% 0, min = 0, step = 0.1)
        )
      },
      command = function(spec) {
        cmd_dotplot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          bin = isTRUE((spec$options %||% list())$bin)
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
      defaults = list(method = "stack", jitter_width = 0.2,
                      jitter_height = 0.1, shape = 19),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          radio_input(
            "chart_opt_method", tr("Method"),
            c("Stack" = "stack", "Jitter" = "jitter"),
            options$method %||% "stack"
          ),
          spin_input("chart_opt_jitter_width", tr("Jitter width (ggplot2)"),
                     options$jitter_width %||% 0.2, min = 0, step = 0.05),
          spin_input("chart_opt_jitter_height", tr("Jitter height (ggplot2)"),
                     options$jitter_height %||% 0.1, min = 0, step = 0.05),
          spin_input("chart_opt_shape", tr("Point shape (ggplot2)"),
                     options$shape %||% 19, min = 0, max = 25, step = 1)
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
      defaults = list(distribution = "norm", line = TRUE, envelope = FALSE,
                      grid = FALSE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          selectInput(
            "chart_opt_distribution", tr("Distribution"),
            choices = stats::setNames(
              c("norm", "unif", "exp"),
              c(tr("Normal"), tr("Uniform"), tr("Exponential"))
            ),
            selected = options$distribution %||% "norm"
          ),
          checkbox_input("chart_opt_line", tr("Reference line"),
                         isTRUE(options$line %||% TRUE)),
          checkbox_input("chart_opt_envelope", tr("Confidence envelope"),
                         isTRUE(options$envelope)),
          checkbox_input("chart_opt_grid", tr("Grid"), isTRUE(options$grid))
        )
      },
      command = function(spec) {
        options <- spec$options %||% list()
        cmd_qqplot(
          spec$dataset, spec$mapping$x %||% "",
          chart_optional(spec$mapping$group),
          distribution = options$distribution %||% "norm",
          line = isTRUE(options$line %||% TRUE),
          envelope = isTRUE(options$envelope),
          grid = isTRUE(options$grid)
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
      defaults = list(error_bars = "se", legend = TRUE, connect = TRUE,
                      error_width = 0.2, point_size = 3),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          radio_input(
            "chart_opt_error_bars", tr("Error bars"),
            c("Standard error" = "se", "Standard deviation" = "sd",
              "Confidence interval" = "ci"),
            options$error_bars %||% "se"
          ),
          checkbox_input("chart_opt_legend", tr("Show legend"),
                         isTRUE(options$legend %||% TRUE)),
          checkbox_input("chart_opt_connect", tr("Connect the means"),
                         isTRUE(options$connect %||% TRUE)),
          spin_input("chart_opt_error_width", tr("Error bar width"),
                     options$error_width %||% 0.2, min = 0, step = 0.05),
          spin_input("chart_opt_point_size", tr("Point size"),
                     options$point_size %||% 3, min = 0.5, step = 0.5)
        )
      },
      command = function(spec) {
        cmd_plot_means(
          spec$dataset, spec$mapping$x %||% "",
          spec$mapping$group %||% "",
          spec$options$error_bars %||% "se",
          isTRUE(spec$options$legend %||% TRUE),
          connect = isTRUE(spec$options$connect %||% TRUE)
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
      defaults = list(type = "p", layout = "", smooth = FALSE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          radio_input(
            "chart_opt_type", tr("Plot type"),
            c("Points" = "p", "Lines" = "l", "Both" = "b"),
            options$type %||% "p"
          ),
          entry_input("chart_opt_layout", tr("Layout (e.g. 2,2):"),
                      options$layout %||% ""),
          checkbox_input("chart_opt_smooth", tr("Add a smooth"),
                         isTRUE(options$smooth))
        )
      },
      command = function(spec) {
        options <- spec$options %||% list()
        cmd_xyplot(
          spec$dataset, spec$mapping$x %||% "", spec$mapping$y %||% "",
          chart_optional(spec$mapping$group),
          options$type %||% "p",
          options$layout %||% "",
          smooth = isTRUE(options$smooth)
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
    ),
    violin = list(
      label = tr("Violin plot"),
      icon = "violin",
      group = "distribution",
      description = tr("Density of a numeric variable by group (ggplot2)."),
      engines = "ggplot2",
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(trim = TRUE, scale = "area", adjust = 0,
                      show_box = TRUE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_trim", tr("Trim tails"),
                         isTRUE(options$trim %||% TRUE)),
          selectInput(
            "chart_opt_scale", tr("Violin scale"),
            choices = stats::setNames(
              c("area", "count", "width"),
              c("Area", "Count", "Width")
            ),
            selected = options$scale %||% "area"
          ),
          spin_input("chart_opt_adjust", tr("Bandwidth adjust"),
                     options$adjust %||% 0, min = 0, step = 0.1),
          checkbox_input("chart_opt_show_box", tr("Overlay a boxplot"),
                         isTRUE(options$show_box %||% TRUE))
        )
      }
    ),
    ecdf = list(
      label = tr("Empirical CDF"),
      icon = "ecdf",
      group = "distribution",
      description = tr("Empirical cumulative distribution (ggplot2)."),
      engines = "ggplot2",
      mapping = list(
        x = list(label = tr("Variable (pick one)"), kind = "numeric"),
        group = list(label = tr("Groups (optional)"), kind = "factor",
                     optional = TRUE)
      ),
      defaults = list(pad = FALSE, linetype = "solid"),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          checkbox_input("chart_opt_pad", tr("Pad the curve"),
                         isTRUE(options$pad)),
          selectInput(
            "chart_opt_linetype", tr("Line style"),
            choices = stats::setNames(
              c("solid", "dashed", "dotted", "longdash"),
              c("Solid", "Dashed", "Dotted", "Long dash")
            ),
            selected = options$linetype %||% "solid"
          )
        )
      }
    ),
    density_2d = list(
      label = tr("2D density"),
      icon = "density2d",
      group = "relationship",
      description = tr("Two-dimensional density contours (ggplot2)."),
      engines = "ggplot2",
      mapping = list(
        x = list(label = tr("Horizontal axis (pick one)"), kind = "numeric"),
        y = list(label = tr("Vertical axis (pick one)"), kind = "numeric")
      ),
      defaults = list(bins = 0, bandwidth = 0, points = TRUE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          spin_input("chart_opt_bins", tr("Contour bins (0 = auto)"),
                     options$bins %||% 0, min = 0, step = 1),
          spin_input("chart_opt_bandwidth", tr("Bandwidth (0 = auto)"),
                     options$bandwidth %||% 0, min = 0, step = 0.1),
          checkbox_input("chart_opt_points", tr("Show points"),
                         isTRUE(options$points %||% TRUE))
        )
      }
    ),
    heatmap = list(
      label = tr("Heatmap"),
      icon = "heatmap",
      group = "relationship",
      description = tr("Tile heatmap of a numeric value by two variables (ggplot2)."),
      engines = "ggplot2",
      mapping = list(
        x = list(label = tr("X variable (pick one)"), kind = "any"),
        y = list(label = tr("Y variable (pick one)"), kind = "any"),
        fill = list(label = tr("Value (numeric)"), kind = "numeric")
      ),
      defaults = list(low = "#f7fbff", high = "#08306b",
                      show_values = FALSE),
      controls = function(spec) {
        options <- spec$options %||% list()
        htmltools::tagList(
          textInput("chart_opt_low", tr("Low colour"),
                    options$low %||% "#f7fbff"),
          textInput("chart_opt_high", tr("High colour"),
                    options$high %||% "#08306b"),
          checkbox_input("chart_opt_show_values", tr("Show values"),
                         isTRUE(options$show_values))
        )
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
    model = list_all_models(state),
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
  slots <- chart_mapping_slots(info, chart_spec_engine(spec), spec$type)

  controls <- lapply(names(slots), function(slot) {
    rule <- slots[[slot]]
    choices <- chart_mapping_choices(state, rule)
    value <- values[[slot]]
    if (identical(rule$kind, "model") && length(choices) == 0L) {
      return(help_text(tr(
        "Estimate a model first: statistical charts can graph a saved model."
      )))
    }
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
#'
#' @param engine Engine to filter by; `NULL` keeps every type.
#' @param analysis Optional analysis family to filter by.
#' @keywords internal
chart_type_choices <- function(engine = "ggplot2", analysis = NULL) {
  types <- chart_types()
  types <- types[vapply(types, function(info) {
    chart_ext_available(info$requires) &&
      (is.null(engine) || engine %in% chart_type_engines(info))
  }, logical(1))]
  if (!is.null(analysis) && nzchar(analysis) &&
      !identical(analysis, "all")) {
    types <- types[vapply(types, function(info) {
      identical(chart_type_analysis(info), analysis)
    }, logical(1))]
  }
  labels <- vapply(types, function(info) info$label, character(1))
  stats::setNames(names(types), unname(labels))
}


# Plugin chart types are additive.  A built-in type always wins by id.
chart_types <- function() {
  registry <- chart_types_builtin()
  extras <- tryCatch(plugin_chart_types(), error = function(e) list())
  for (id in names(extras)) {
    if (!id %in% names(registry)) registry[[id]] <- extras[[id]]
  }
  # Every descriptor knows its identifier, so helpers can classify a type
  # without walking the registry again.
  stats::setNames(
    lapply(names(registry), function(id) {
      entry <- registry[[id]]
      if (is.null(entry$id)) entry$id <- id
      entry
    }),
    names(registry)
  )
}
