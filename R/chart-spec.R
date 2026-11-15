# Chart specification -------------------------------------------------------
#
# A chart specification is a plain list.  It is the single source of truth for
# the builder, the preview, the applied command, the gallery metadata and the
# round-trip: every representation is derived from the same object.
#
# The base engine always emits the command of the equivalent Rcmdr dialog, so
# the Chart Studio never introduces a second command dialect.  The optional
# ggplot2 engine is an opt-in alternative and is validated separately.

chart_quote <- function(x) {
  encodeString(as.character(x), quote = "\"")
}

#' Default palettes available to the Chart Studio
#' @keywords internal
chart_palettes <- function() {
  list(
    default = NULL,
    colorblind = c(
      "#0072B2", "#E69F00", "#009E73", "#CC79A7",
      "#F0E442", "#56B4E9", "#D55E00", "#000000"
    ),
    tableau = c(
      "#4E79A7", "#F28E2B", "#E15759", "#76B7B2",
      "#59A14F", "#EDC948", "#B07AA1", "#FF9DA7"
    ),
    viridis = c(
      "#440154", "#472D7B", "#3B528B", "#2C728E",
      "#21918C", "#28AE80", "#5EC962", "#ADD51C", "#FDE725"
    ),
    greys = grDevices::grey.colors(8)
  )
}

#' Palette choices for selectors
#' @keywords internal
chart_palette_choices <- function() {
  stats::setNames(
    names(chart_palettes()),
    c("R default", "Colorblind safe", "Tableau", "Viridis", "Greys")
  )
}

#' Colours of a named palette
#' @keywords internal
chart_palette_colors <- function(name) {
  palettes <- chart_palettes()
  if (is.null(name) || !nzchar(name)) return(NULL)
  palettes[[name]] %||% NULL
}

#' Default chart mapping
#' @keywords internal
chart_mapping_defaults <- function(type_info) {
  slots <- names(type_info$mapping %||% list())
  values <- lapply(slots, function(slot) {
    if (isTRUE(type_info$mapping[[slot]]$multiple)) character() else NULL
  })
  stats::setNames(values, slots)
}

#' Default chart theme
#' @keywords internal
chart_theme_defaults <- function() {
  list(
    engine = "base",
    palette = "default",
    base_size = 12,
    grid = TRUE,
    legend = "right",
    background = "white",
    ggplot_theme = "minimal"
  )
}

#' Default chart labels
#' @keywords internal
chart_label_defaults <- function() {
  list(title = "", subtitle = "", x = "", y = "", caption = "", tag = "")
}

#' Default chart size
#' @keywords internal
chart_size_defaults <- function() {
  list(width = 800L, height = 600L, dpi = 96L)
}

#' Create a chart specification
#'
#' @param type One of the identifiers returned by [chart_types()].
#' @param dataset Name of the active data set.
#' @param mapping Named list of variable mappings.
#' @param options Type-specific options.
#' @param theme Palette, base size, grid, legend and background.
#' @param labels Title, axis labels and caption.
#' @param size Width, height and resolution.
#' @param engine `"base"` or `"ggplot2"`.
#' @param id Optional spec identifier.
#' @return A list of class `RcmdrChartSpec`.
#' @keywords internal
chart_spec <- function(type = "histogram", dataset = NULL,
                       mapping = list(), options = list(),
                       theme = list(), labels = list(), size = list(),
                       engine = NULL, id = NULL) {
  info <- chart_type(type)
  if (is.null(info)) {
    stop(sprintf("Unknown chart type: %s", type), call. = FALSE)
  }
  theme <- utils::modifyList(chart_theme_defaults(), theme)
  if (!is.null(engine)) theme$engine <- engine
  if (is.null(mapping) || !is.list(mapping)) mapping <- list()
  if (is.null(options) || !is.list(options)) options <- list()
  spec <- list(
    version = 1L,
    id = id,
    dataset = dataset,
    type = type,
    mapping = utils::modifyList(chart_mapping_defaults(info), mapping),
    options = utils::modifyList(info$defaults %||% list(), options),
    theme = theme,
    labels = utils::modifyList(chart_label_defaults(), labels),
    size = utils::modifyList(chart_size_defaults(), size)
  )
  class(spec) <- c("RcmdrChartSpec", "list")
  spec
}

#' Chart engine of a specification
#' @keywords internal
chart_spec_engine <- function(spec) {
  spec$theme$engine %||% "base"
}

#' Chart type descriptor of a specification
#' @keywords internal
chart_spec_info <- function(spec) chart_type(spec$type)

#' Validate a chart specification
#'
#' @param spec A chart specification.
#' @param state Optional application state used to check the data set and the
#'   selected variables.
#' @return A character vector of problems; empty when the spec is valid.
#' @keywords internal
chart_spec_validate <- function(spec, state = NULL) {
  problems <- character()
  if (is.null(spec) || !is.list(spec)) return("The chart specification is empty.")
  info <- chart_type(spec$type %||% "")
  if (is.null(info)) {
    return(sprintf("Unknown chart type: %s", spec$type %||% ""))
  }
  engine <- chart_spec_engine(spec)
  if (!chart_type_available(spec$type, engine)) {
    problems <- c(problems, sprintf(
      "The %s chart is only available with the ggplot2 engine.",
      info$label %||% spec$type
    ))
  }

  mapping <- spec$mapping %||% list()
  slots <- chart_mapping_slots(info, engine, spec$type)
  for (slot in names(slots)) {
    rule <- slots[[slot]]
    value <- mapping[[slot]]
    value <- value[!is.na(value) & nzchar(as.character(value))]
    if (!isTRUE(rule$optional) && length(value) == 0L) {
      problems <- c(problems, sprintf(
        "The %s mapping is required.", rule$label %||% slot
      ))
    }
    if (isTRUE(rule$multiple) && length(value) == 1L &&
        !isTRUE(rule$optional)) {
      # A single value is valid for a multiple mapping.
    }
  }

  if (!is.null(state)) {
    if (is.null(spec$dataset) || !nzchar(spec$dataset)) {
      problems <- c(problems, "Select a data set.")
    } else {
      df <- tryCatch(
        get0(spec$dataset, envir = state$env, inherits = FALSE),
        error = function(e) NULL
      )
      if (is.null(df) || !is.data.frame(df)) {
        problems <- c(problems, "The selected data set is not available.")
      } else {
        used <- unlist(mapping, use.names = FALSE)
        used <- as.character(used[!is.na(used) & nzchar(as.character(used))])
        missing <- setdiff(used, names(df))
        if (length(missing) > 0L) {
          problems <- c(problems, sprintf(
            "Unknown variable(s): %s", paste(missing, collapse = ", ")
          ))
        }
        for (slot in names(slots)) {
          rule <- slots[[slot]]
          value <- as.character(mapping[[slot]] %||% character())
          value <- value[nzchar(value)]
          if (length(value) == 0L) next
          check <- switch(
            rule$kind %||% "any",
            numeric = numeric_variables(state),
            factor = factor_variables(state),
            any = variables(state),
            variables(state)
          )
          invalid <- setdiff(value, check)
          if (length(invalid) > 0L && identical(rule$kind, "numeric")) {
            problems <- c(problems, sprintf(
              "%s must be numeric: %s",
              rule$label %||% slot, paste(invalid, collapse = ", ")
            ))
          }
          if (length(invalid) > 0L && identical(rule$kind, "factor")) {
            problems <- c(problems, sprintf(
              "%s must be a factor: %s",
              rule$label %||% slot, paste(invalid, collapse = ", ")
            ))
          }
        }
      }
    }
  }

  size <- spec$size %||% chart_size_defaults()
  if (!is.numeric(size$width) || size$width < 200) {
    problems <- c(problems, "The preview width must be at least 200 pixels.")
  }
  if (!is.numeric(size$height) || size$height < 150) {
    problems <- c(problems, "The preview height must be at least 150 pixels.")
  }

  if (identical(engine, "ggplot2") && !requireNamespace("ggplot2", quietly = TRUE)) {
    problems <- c(problems,
                  "The ggplot2 engine requires the ggplot2 package.")
  }

  problems
}

#' Whether a specification is valid
#' @keywords internal
chart_spec_ready <- function(spec, state = NULL) {
  length(chart_spec_validate(spec, state)) == 0L
}

#' Base command of a specification, without theme or labels
#' @keywords internal
chart_spec_plot_command <- function(spec) {
  info <- chart_type(spec$type)
  if (is.null(info)) stop("Unknown chart type.", call. = FALSE)
  command <- info$command(spec)
  paste(command, collapse = "\n")
}

#' Palette and device settings emitted before the plot
#' @keywords internal
chart_theme_prefix <- function(spec) {
  commands <- character()
  theme <- spec$theme %||% chart_theme_defaults()

  palette <- chart_palette_colors(theme$palette %||% "default")
  if (!is.null(palette) && length(palette) > 0L) {
    commands <- c(commands, cmd_set_palette(palette))
  }

  arguments <- character()
  background <- theme$background %||% "white"
  if (!identical(background, "white")) {
    arguments <- c(arguments, sprintf("bg = %s", chart_quote(background)))
  }
  base_size <- suppressWarnings(as.numeric(theme$base_size %||% 12))
  if (!is.na(base_size) && base_size > 0 && base_size != 12) {
    arguments <- c(arguments, sprintf("cex = %.2f", base_size / 12))
  }
  if (length(arguments) > 0L) {
    commands <- c(commands, sprintf("par(%s)", paste(arguments, collapse = ", ")))
  }
  commands
}

#' Title and axis labels emitted after the plot
#' @keywords internal
chart_label_commands <- function(spec) {
  labels <- spec$labels %||% chart_label_defaults()
  arguments <- character()
  if (nzchar(labels$title %||% "")) {
    arguments <- c(arguments, sprintf("main = %s", chart_quote(labels$title)))
  }
  if (nzchar(labels$x %||% "")) {
    arguments <- c(arguments, sprintf("xlab = %s", chart_quote(labels$x)))
  }
  if (nzchar(labels$y %||% "")) {
    arguments <- c(arguments, sprintf("ylab = %s", chart_quote(labels$y)))
  }
  if (nzchar(labels$caption %||% "")) {
    arguments <- c(arguments, sprintf("sub = %s", chart_quote(labels$caption)))
  }
  if (length(arguments) == 0L) return(character())
  sprintf("title(%s)", paste(arguments, collapse = ", "))
}

#' Complete command of a specification
#'
#' With the default theme and empty labels this is exactly the command of the
#' equivalent dialog.  Palette, device settings and labels are emitted only
#' when the user changes them.
#' @keywords internal
chart_spec_command <- function(spec) {
  if (identical(chart_spec_engine(spec), "ggplot2")) {
    return(chart_ggplot_command(spec))
  }
  if (!chart_type_available(spec$type, "base")) {
    stop("This chart type is only available with the ggplot2 engine.",
         call. = FALSE)
  }
  paste(
    c(chart_theme_prefix(spec), chart_spec_plot_command(spec),
      chart_label_commands(spec)),
    collapse = "\n"
  )
}

#' Interactive plot expression of a specification
#' @keywords internal
chart_spec_interactive <- function(spec) {
  if (identical(chart_spec_engine(spec), "ggplot2")) {
    code <- tryCatch(chart_ggplot_interactive(spec),
                     error = function(e) NULL)
    return(if (is.null(code) || !nzchar(code)) NULL else code)
  }
  info <- chart_type(spec$type)
  if (is.null(info) || is.null(info$interactive)) return(NULL)
  code <- tryCatch(info$interactive(spec), error = function(e) NULL)
  if (is.null(code) || !nzchar(code)) NULL else code
}

#' Cache key of a specification
#'
#' The key includes the data set shape and variable names so that a preview is
#' invalidated when the underlying data change.
#' @keywords internal
chart_spec_key <- function(spec, state = NULL) {
  if (is.null(spec)) return("")
  body <- spec[c("type", "dataset", "mapping", "options", "theme", "labels",
                 "size")]
  text <- paste(utils::capture.output(utils::str(body)), collapse = "\n")
  if (!is.null(state) && !is.null(spec$dataset)) {
    df <- tryCatch(
      get0(spec$dataset, envir = state$env, inherits = FALSE),
      error = function(e) NULL
    )
    if (is.data.frame(df)) {
      text <- paste(
        text,
        sprintf("%d:%d", nrow(df), ncol(df)),
        paste(names(df), collapse = "|"),
        sep = "::"
      )
    }
  }
  text
}

#' Default title of a specification
#' @keywords internal
chart_spec_title <- function(spec) {
  mapping <- spec$mapping %||% list()
  x <- mapping$x %||% mapping$variable %||% ""
  y <- mapping$y %||% ""
  group <- mapping$group %||% ""
  title <- switch(
    spec$type,
    histogram = sprintf(tr("Histogram of %s"), x),
    density = sprintf(tr("Density of %s"), x),
    boxplot = if (nzchar(group)) {
      sprintf(tr("Boxplot of %s by %s"), x, group)
    } else {
      sprintf(tr("Boxplot of %s"), paste(mapping$x %||% "", collapse = ", "))
    },
    scatter = sprintf(tr("%s versus %s"), y, x),
    line = sprintf(tr("%s over %s"), paste(y, collapse = ", "), x),
    bar = sprintf(tr("Bar graph of %s"), x),
    dot = sprintf(tr("Dot plot of %s"), x),
    strip = sprintf(tr("Strip chart of %s"), x),
    qq = sprintf(tr("Quantile-comparison plot of %s"), x),
    means = sprintf(tr("Means of %s by %s"), x, group),
    xyplot = sprintf(tr("%s versus %s"), y, x),
    violin = sprintf(tr("Violin plot of %s"), x),
    ecdf = sprintf(tr("ECDF of %s"), x),
    density_2d = sprintf(tr("2D density of %s and %s"), x,
                         paste(y, collapse = ", ")),
    heatmap = sprintf(tr("Heatmap of %s"),
                      paste(mapping$fill %||% "", collapse = ", ")),
    tr("Chart")
  )
  as.character(title)[[1L]]
}
