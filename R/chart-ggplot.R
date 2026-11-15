# ggplot2 engine -------------------------------------------------------------
#
# One builder per chart type, shared options, facets, scales, coordinates,
# themes and labels.  The generated expression is a single ggplot object;
# chart_spec_command() wraps it in print().

utils::globalVariables(c("x", "y"))

#' ggplot2 mapping slots added on top of the base ones
#' @keywords internal
chart_ggplot_slots <- function(type) {
  facet <- list(
    facet = list(label = tr("Facet (optional)"), kind = "any",
                 optional = TRUE)
  )
  extra <- switch(
    type,
    scatter = list(
      size = list(label = tr("Size by (optional)"), kind = "numeric",
                  optional = TRUE),
      label = list(label = tr("Label by (optional)"), kind = "any",
                   optional = TRUE)
    ),
    list()
  )
  c(facet, extra)
}

#' Mapping slots for an engine
#' @keywords internal
chart_mapping_slots <- function(info, engine = "base", type = NULL) {
  slots <- info$mapping %||% list()
  if (identical(engine, "ggplot2")) {
    slots <- c(slots, chart_ggplot_slots(type %||% ""))
  }
  slots
}

#' Defaults for the common ggplot2 options
#' @keywords internal
chart_ggplot_option_defaults <- function() {
  list(
    alpha = 0.7,
    position = "identity",
    binwidth = 0,
    smooth_method = "lm",
    smooth_se = FALSE,
    jitter = 0,
    flip = FALSE,
    facet_scales = "fixed",
    facet_ncol = 0,
    shape = 19
  )
}

chart_ggplot_theme_functions <- c(
  minimal = "theme_minimal", bw = "theme_bw", classic = "theme_classic",
  light = "theme_light", dark = "theme_dark", void = "theme_void"
)

#' ggplot2 theme function name
#' @keywords internal
chart_ggplot_theme_function <- function(theme) {
  name <- theme$ggplot_theme %||% "minimal"
  if (!name %in% names(chart_ggplot_theme_functions)) name <- "minimal"
  unname(chart_ggplot_theme_functions[[name]])
}

chart_gg_optional <- function(value) {
  value <- as.character(value %||% "")[1L]
  if (is.null(value) || is.na(value) || !nzchar(value)) "" else value
}

chart_gg_number <- function(value, default = NA_real_, min = NULL,
                            max = NULL) {
  number <- suppressWarnings(as.numeric(value %||% default))
  if (is.na(number)) return(default)
  if (!is.null(min) && number < min) number <- min
  if (!is.null(max) && number > max) number <- max
  number
}

chart_gg_aes <- function(items) {
  items <- items[!is.na(items) & nzchar(items)]
  if (length(items) == 0L) return("ggplot2::aes()")
  sprintf("ggplot2::aes(%s)", paste(items, collapse = ", "))
}

chart_gg_alpha <- function(options) {
  alpha <- chart_gg_number(options$alpha %||% 0.7, default = 0.7,
                           min = 0, max = 1)
  sprintf("alpha = %s", format(alpha, digits = 3))
}

chart_gg_position <- function(options, fallback = "identity") {
  position <- options$position %||% fallback
  if (!position %in% c("identity", "dodge", "stack", "fill", "jitter",
                       "jitterdodge")) {
    position <- fallback
  }
  chart_quote(position)
}

chart_gg_palette <- function(spec) {
  theme <- spec$theme %||% list()
  chart_palette_colors(theme$palette %||% "default")
}

chart_gg_manual_scale <- function(aesthetic, values, names = NULL) {
  if (is.null(values) || length(values) == 0L) return(NULL)
  entries <- chart_quote(values)
  if (!is.null(names) && length(names) > 0L) {
    values <- rep_len(values, length(names))
    entries <- sprintf("%s = %s", names, chart_quote(values))
  }
  sprintf(
    "ggplot2::scale_%s_manual(values = c(%s))",
    aesthetic, paste(entries, collapse = ", ")
  )
}

chart_gg_facet <- function(facet, options, layout = NULL) {
  if (!nzchar(facet)) return(NULL)
  scales <- options$facet_scales %||% "fixed"
  if (!scales %in% c("fixed", "free", "free_x", "free_y")) scales <- "fixed"
  ncol <- suppressWarnings(as.integer(options$facet_ncol %||% 0L))
  if (is.na(ncol) || ncol < 1L) {
    layout_value <- as.character(layout %||% "")[1L]
    if (is.na(layout_value)) layout_value <- ""
    parts <- strsplit(layout_value, ",", fixed = TRUE)[[1L]]
    ncol <- if (length(parts) > 0L) {
      suppressWarnings(as.integer(parts[[1L]]))
    } else {
      NA_integer_
    }
  }
  arguments <- c(
    sprintf("ggplot2::vars(%s)", facet),
    sprintf("scales = %s", chart_quote(scales))
  )
  if (!is.na(ncol) && ncol > 0L) {
    arguments <- c(arguments, sprintf("ncol = %d", ncol))
  }
  sprintf("ggplot2::facet_wrap(%s)", paste(arguments, collapse = ", "))
}

chart_gg_theme <- function(spec) {
  theme <- spec$theme %||% list()
  options <- spec$options %||% list()
  base_size <- chart_gg_number(theme$base_size %||% 12, default = 12,
                               min = 6, max = 32)
  code <- sprintf("ggplot2::%s(base_size = %s)",
                  chart_ggplot_theme_function(theme),
                  format(base_size, digits = 3))
  extra <- character()
  if (isFALSE(theme$grid %||% TRUE)) {
    extra <- c(extra, "panel.grid = ggplot2::element_blank()")
  }
  legend <- theme$legend %||% "right"
  if (isFALSE(options$legend %||% TRUE)) legend <- "none"
  if (nzchar(legend)) {
    extra <- c(extra, sprintf("legend.position = %s", chart_quote(legend)))
  }
  background <- theme$background %||% "white"
  if (!identical(background, "white")) {
    extra <- c(extra, sprintf(
      "plot.background = ggplot2::element_rect(fill = %s, colour = NA)",
      chart_quote(background)
    ))
  }
  if (length(extra) > 0L) {
    code <- paste0(code, " + ggplot2::theme(",
                   paste(extra, collapse = ", "), ")")
  }
  code
}

chart_gg_labs <- function(spec) {
  labels <- spec$labels %||% list()
  items <- character()
  add <- function(name, value) {
    value <- as.character(value %||% "")[1L]
    if (!is.na(value) && nzchar(value)) {
      items <<- c(items, sprintf("%s = %s", name, chart_quote(value)))
    }
  }
  add("title", labels$title)
  add("subtitle", labels$subtitle)
  add("x", labels$x)
  add("y", labels$y)
  add("caption", labels$caption)
  add("tag", labels$tag)
  if (length(items) == 0L) return(NULL)
  sprintf("ggplot2::labs(%s)", paste(items, collapse = ", "))
}

#' ggplot2 object for a specification
#'
#' Returns the ggplot expression without `print()`, so it can also feed
#' `plotly::ggplotly()`.
#' @keywords internal
chart_ggplot_object <- function(spec) {
  type <- spec$type
  dataset <- spec$dataset %||% "data"
  mapping <- spec$mapping %||% list()
  options <- utils::modifyList(chart_ggplot_option_defaults(),
                               spec$options %||% list())
  x <- chart_gg_optional(mapping$x)
  y <- as.character(mapping$y %||% character())
  y <- y[!is.na(y) & nzchar(y)]
  first_y <- if (length(y) > 0L) y[[1L]] else ""
  group <- chart_gg_optional(mapping$group)
  facet <- chart_gg_optional(mapping$facet)
  size_by <- chart_gg_optional(mapping$size)
  label_by <- chart_gg_optional(mapping$label)
  palette <- chart_gg_palette(spec)
  alpha <- chart_gg_alpha(options)

  aes_items <- character()
  layers <- character()
  scales <- character()
  facet_code <- chart_gg_facet(facet, options)
  use_fill <- FALSE
  use_colour <- FALSE

  if (type %in% c("histogram", "density", "bar")) {
    aes_items <- c(sprintf("x = %s", x))
    if (nzchar(group)) {
      aes_items <- c(aes_items, sprintf("fill = %s", group))
      use_fill <- TRUE
    }
  } else if (identical(type, "boxplot")) {
    if (nzchar(group)) {
      aes_items <- c(sprintf("x = %s", group), sprintf("y = %s", x),
                     sprintf("fill = %s", group))
      use_fill <- TRUE
    } else {
      aes_items <- c("x = factor(1)", sprintf("y = %s", x))
    }
  } else if (identical(type, "scatter")) {
    aes_items <- c(sprintf("x = %s", x), sprintf("y = %s", first_y))
    if (nzchar(group)) {
      aes_items <- c(aes_items, sprintf("colour = %s", group))
      use_colour <- TRUE
    }
    if (nzchar(size_by)) aes_items <- c(aes_items, sprintf("size = %s", size_by))
  } else if (identical(type, "line")) {
    aes_items <- c(sprintf("x = %s", x))
  } else if (identical(type, "dot")) {
    aes_items <- c(sprintf("x = %s", x))
    if (nzchar(group) && !nzchar(facet)) {
      facet_code <- chart_gg_facet(group, options)
    }
  } else if (identical(type, "strip")) {
    if (nzchar(group)) {
      aes_items <- c(sprintf("x = %s", group), sprintf("y = %s", x),
                     sprintf("colour = %s", group))
      use_colour <- TRUE
    } else {
      aes_items <- c("x = factor(1)", sprintf("y = %s", x))
    }
  } else if (identical(type, "qq")) {
    aes_items <- c(sprintf("sample = %s", x))
    if (nzchar(group)) {
      aes_items <- c(aes_items, sprintf("colour = %s", group))
      use_colour <- TRUE
    }
  } else if (identical(type, "means")) {
    aes_items <- c(sprintf("x = %s", group), sprintf("y = %s", x))
    if (nzchar(group)) {
      aes_items <- c(aes_items, sprintf("colour = %s", group))
      use_colour <- TRUE
    }
  } else if (identical(type, "xyplot")) {
    aes_items <- c(sprintf("x = %s", x), sprintf("y = %s", first_y))
    if (nzchar(group) && !nzchar(facet)) {
      facet_code <- chart_gg_facet(group, options, options$layout)
    }
  }

  if (identical(type, "histogram")) {
    scale <- options$scale %||% "frequency"
    if (identical(scale, "density")) {
      aes_items <- c(aes_items, "y = ggplot2::after_stat(density)")
    } else if (identical(scale, "percent")) {
      aes_items <- c(aes_items,
                     "y = ggplot2::after_stat(count / sum(count) * 100)")
    }
  }

  if (identical(type, "histogram")) {
    binwidth <- chart_gg_number(options$binwidth, default = 0, min = 0)
    arguments <- c(
      sprintf("bins = %d", as.integer(chart_gg_number(
        options$bins %||% 30, default = 30, min = 1
      ))),
      if (binwidth > 0) sprintf("binwidth = %s", format(binwidth, digits = 3)),
      sprintf("position = %s", chart_gg_position(options)),
      alpha,
      "colour = \"white\"",
      if (nzchar(group)) NULL else "fill = \"#4E79A7\""
    )
    layers <- sprintf("ggplot2::geom_histogram(%s)",
                      paste(arguments[!is.na(arguments)], collapse = ", "))
  } else if (identical(type, "density")) {
    adjust <- chart_gg_number(options$bw, default = 0, min = 0)
    arguments <- c(
      "linewidth = 1",
      alpha,
      if (adjust > 0) sprintf("adjust = %s", format(adjust, digits = 3))
    )
    layers <- sprintf("ggplot2::geom_density(%s)",
                      paste(arguments, collapse = ", "))
  } else if (identical(type, "boxplot")) {
    notch <- isTRUE(options$notch)
    box_arguments <- c(
      sprintf("position = %s", chart_gg_position(options)),
      alpha,
      if (notch) "notch = TRUE" else NULL,
      if (notch) sprintf("notchwidth = %s", format(
        chart_gg_number(options$notchwidth %||% 0.5, default = 0.5,
                        min = 0, max = 1), digits = 3)) else NULL,
      if (isTRUE(options$varwidth)) "varwidth = TRUE" else NULL,
      if (chart_gg_number(options$width %||% 0, default = 0, min = 0) > 0) {
        sprintf("width = %s", format(
          chart_gg_number(options$width, default = 0, min = 0), digits = 3))
      } else {
        NULL
      },
      if (isFALSE(options$outline %||% TRUE)) "outlier.shape = NA" else NULL
    )
    layers <- sprintf("ggplot2::geom_boxplot(%s)",
                      paste(box_arguments[!is.na(box_arguments)],
                            collapse = ", "))
    jitter <- chart_gg_number(options$jitter, default = 0, min = 0)
    if (jitter > 0) {
      layers <- c(layers, sprintf(
        "ggplot2::geom_jitter(width = %s, height = 0, %s)",
        format(jitter, digits = 3), alpha
      ))
    }
  } else if (identical(type, "scatter")) {
    method <- NULL
    if (isTRUE(options$regression)) {
      method <- "lm"
    } else if (isTRUE(options$smooth)) {
      method <- options$smooth_method %||% "lm"
      if (!method %in% c("lm", "loess", "gam")) method <- "lm"
    }
    if (!is.null(method)) {
      layers <- c(
        sprintf("ggplot2::geom_smooth(method = %s, se = %s)",
                chart_quote(method),
                if (isTRUE(options$smooth_se)) "TRUE" else "FALSE")
      )
    }
    jitter <- chart_gg_number(options$jitter, default = 0, min = 0)
    if (jitter > 0) {
      layers <- c(layers, sprintf(
        "ggplot2::geom_jitter(width = %s, height = %s, %s, shape = %d)",
        format(jitter, digits = 3), format(jitter, digits = 3), alpha,
        as.integer(chart_gg_number(options$shape %||% 19, default = 19))
      ))
    } else {
      layers <- c(layers, sprintf(
        "ggplot2::geom_point(%s, shape = %d)", alpha,
        as.integer(chart_gg_number(options$shape %||% 19, default = 19))
      ))
    }
    if (nzchar(label_by)) {
      layers <- c(layers, sprintf(
        "ggplot2::geom_text(ggplot2::aes(label = %s), nudge_y = 0.1, check_overlap = TRUE)",
        label_by
      ))
    }
    if (isTRUE(options$ellipse)) {
      layers <- c(layers, "ggplot2::stat_ellipse()")
    }
  } else if (identical(type, "line")) {
    series <- if (length(y) > 0L) y else character()
    if (length(series) == 0L) {
      layers <- character()
    } else if (length(series) == 1L) {
      layers <- sprintf(
        "ggplot2::geom_line(ggplot2::aes(y = %s), linewidth = 1)",
        series[[1L]]
      )
    } else {
      layers <- vapply(series, function(variable) {
        sprintf(
          "ggplot2::geom_line(ggplot2::aes(y = %s, colour = %s), linewidth = 1)",
          variable, chart_quote(variable)
        )
      }, character(1))
      if (!is.null(palette)) {
        colour_scale <- chart_gg_manual_scale("colour", palette, series)
        if (!is.null(colour_scale)) scales <- c(scales, colour_scale)
      }
    }
  } else if (identical(type, "bar")) {
    position <- options$position %||% if (nzchar(group)) "dodge" else "stack"
    if (identical(position, "identity") && nzchar(group)) position <- "dodge"
    layers <- sprintf(
      "ggplot2::geom_bar(position = %s, %s, colour = \"white\")",
      chart_gg_position(list(position = position), position), alpha
    )
  } else if (identical(type, "dot")) {
    layers <- sprintf(
      "ggplot2::geom_dotplot(binaxis = \"x\", stackdir = \"center\", %s)",
      alpha
    )
  } else if (identical(type, "strip")) {
    jitter <- chart_gg_number(options$jitter, default = 0.2, min = 0)
    layers <- sprintf(
      "ggplot2::geom_jitter(width = %s, height = 0.1, %s, shape = %d)",
      format(jitter, digits = 3), alpha,
      as.integer(chart_gg_number(options$shape %||% 19, default = 19))
    )
  } else if (identical(type, "qq")) {
    layers <- c(
      "ggplot2::stat_qq()",
      "ggplot2::stat_qq_line()"
    )
  } else if (identical(type, "means")) {
    error_bars <- options$error_bars %||% "se"
    fun <- switch(
      error_bars,
      sd = "mean_sdl",
      ci = "mean_cl_normal",
      "mean_se"
    )
    layers <- c(
      "ggplot2::stat_summary(fun = \"mean\", geom = \"point\", size = 3)",
      sprintf(
        "ggplot2::stat_summary(fun.data = \"%s\", geom = \"errorbar\", width = 0.2)",
        fun
      )
    )
  } else if (identical(type, "xyplot")) {
    plot_type <- options$type %||% "p"
    if (plot_type %in% c("p", "b")) {
      layers <- c(layers, "ggplot2::geom_point()")
    }
    if (plot_type %in% c("l", "b")) {
      layers <- c(layers, "ggplot2::geom_line()")
    }
  }

  if (use_fill) {
    scale <- chart_gg_manual_scale("fill", palette)
    if (!is.null(scale)) scales <- c(scales, scale)
  }
  if (use_colour) {
    scale <- chart_gg_manual_scale("colour", palette)
    if (!is.null(scale)) scales <- c(scales, scale)
  }

  log <- options$log %||% ""
  if (grepl("x", log, fixed = TRUE)) {
    scales <- c(scales, "ggplot2::scale_x_log10()")
  }
  if (grepl("y", log, fixed = TRUE)) {
    scales <- c(scales, "ggplot2::scale_y_log10()")
  }
  flip <- isTRUE(options$flip) ||
    (identical(type, "boxplot") && isTRUE(options$horizontal))
  coord <- if (flip) "ggplot2::coord_flip()" else NULL

  pieces <- c(
    sprintf("ggplot2::ggplot(%s, %s)", dataset, chart_gg_aes(aes_items)),
    layers,
    scales,
    facet_code,
    chart_gg_theme(spec),
    chart_gg_labs(spec),
    coord
  )
  pieces <- pieces[!is.na(pieces) & nzchar(pieces)]
  paste(pieces, collapse = " + ")
}

#' Complete ggplot2 command
#' @keywords internal
chart_ggplot_command <- function(spec) {
  sprintf("print(%s)", chart_ggplot_object(spec))
}

#' Whether plotly can convert ggplot2 objects in this installation
#'
#' plotly and ggplot2 versions can be incompatible.  Probe once so the UI does
#' not offer an interactive version that cannot be built.
#' @keywords internal
ggplotly_available <- function() {
  if (!plotly_available() || !requireNamespace("ggplot2", quietly = TRUE)) {
    return(FALSE)
  }
  if (!is.null(.ggplotly_cache$ok)) return(.ggplotly_cache$ok)
  value <- tryCatch({
    data <- data.frame(x = 1:3, y = 1:3)
    widget <- plotly::ggplotly(
      ggplot2::ggplot(data, ggplot2::aes(x = x, y = y)) +
        ggplot2::geom_point()
    )
    !is.null(widget)
  }, error = function(e) FALSE)
  .ggplotly_cache$ok <- value
  value
}

.ggplotly_cache <- new.env(parent = emptyenv())

#' Interactive ggplot2 expression
#' @keywords internal
chart_ggplot_interactive <- function(spec) {
  if (!ggplotly_available()) return(NULL)
  sprintf("plotly::ggplotly(%s)", chart_ggplot_object(spec))
}

#' Types supported by the ggplot2 engine
#' @keywords internal
chart_ggplot_types <- function() chart_type_ids()
