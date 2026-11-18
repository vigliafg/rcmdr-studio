# Chart Studio ---------------------------------------------------------------
#
# The Chart Studio is a builder, a preview and a gallery on top of the same
# plotting engine used by the Rcmdr dialogs.  Applying a chart runs exactly one
# reproducible command (plus an optional palette/labels prefix) and attaches
# the specification to the resulting plot so that it can be reopened later.

# Gallery --------------------------------------------------------------------

.chart_preview_cache <- new.env(parent = emptyenv())
.chart_preview_cache$entries <- list()

#' Identify the chart type of a legacy plot from its command
#' @keywords internal
chart_type_from_code <- function(code) {
  code <- paste(code, collapse = " ")
  patterns <- c(
    histogram = "\\bHist\\s*\\(",
    density = "\\bdensityPlot\\s*\\(",
    boxplot = "\\bBoxplot\\s*\\(",
    scatter = "\\bscatterplot\\s*\\(",
    line = "\\blineplot\\s*\\(",
    bar = "\\bBarplot\\s*\\(",
    dot = "\\bDotplot\\s*\\(",
    strip = "\\bstripchart\\s*\\(",
    qq = "\\bqqPlot\\s*\\(",
    means = "\\bplotMeans\\s*\\(",
    xyplot = "\\bxyplot\\s*\\("
  )
  for (name in names(patterns)) {
    if (grepl(patterns[[name]], code, perl = TRUE)) return(name)
  }
  ""
}

#' Title of a gallery entry
#' @keywords internal
plot_title <- function(plot) {
  if (!is.null(plot$title) && nzchar(plot$title)) return(plot$title)
  if (!is.null(plot$spec)) {
    title <- plot$spec$labels$title %||% ""
    if (!nzchar(title)) title <- chart_spec_title(plot$spec)
    if (nzchar(title)) return(title)
  }
  type <- chart_type_from_code(plot$code)
  if (nzchar(type)) return(chart_type(type)$label %||% type)
  tr("Plot")
}

#' Locate a plot by index or identifier
#' @keywords internal
plot_locate <- function(state, key) {
  plots <- state$plots %||% list()
  if (length(plots) == 0L) return(NA_integer_)
  if (is.numeric(key) && length(key) == 1L) {
    key <- as.integer(key)
    if (!is.na(key) && key >= 1L && key <= length(plots)) return(key)
    return(NA_integer_)
  }
  if (is.character(key) && length(key) == 1L) {
    ids <- vapply(plots, function(plot) plot$id %||% "", character(1))
    match(key, ids)
  } else {
    NA_integer_
  }
}

#' Get one gallery entry
#' @keywords internal
plot_entry <- function(state, key) {
  index <- plot_locate(state, key)
  if (is.na(index)) return(NULL)
  state$plots[[index]]
}

#' Register a plot entry
#'
#' Used by [run_plot_command()] and by tests.  The entry gets a stable id and
#' the session counter is advanced when the id is generated here.
#' @keywords internal
plot_register <- function(state, plot) {
  if (is.null(plot)) return(invisible(NA_integer_))
  before <- undo_gallery_snapshot(state)
  if (is.null(plot$id)) {
    state$plot_counter <- as.integer(state$plot_counter %||% 0L) + 1L
    plot$id <- sprintf("plot-%04d", state$plot_counter)
  }
  plot$tags <- plot$tags %||% character()
  plot$pinned <- isTRUE(plot$pinned)
  existing <- vapply(state$plots %||% list(), function(entry) {
    suppressWarnings(as.numeric(entry$order %||% 0))
  }, numeric(1))
  plot$order <- plot$order %||% (max(c(0, existing), na.rm = TRUE) + 1)
  state$plots <- c(state$plots %||% list(), list(plot))
  index <- length(state$plots)
  state$plots[[index]]$index <- index
  state_touch(state)
  undo_record(state, "gallery", tr("Add chart"), before,
              undo_gallery_snapshot(state))
  invisible(index)
}

#' Pinned charts in their saved order
#' @keywords internal
plot_pinned_order <- function(state) {
  plots <- state$plots %||% list()
  pinned <- which(vapply(plots, function(plot) isTRUE(plot$pinned), logical(1)))
  if (length(pinned) < 2L) return(pinned)
  key <- vapply(plots[pinned], function(plot) {
    suppressWarnings(as.numeric(plot$order %||% plot$index %||% 0))
  }, numeric(1))
  pinned[order(key)]
}

#' Move a pinned chart to another position
#'
#' Both arguments are list indices, the values the gallery already puts in
#' `data-rcmdr-sortable-id`.  Unpinned charts keep their reverse-chronological
#' place: the drag order only belongs to the pinned block.
#' @keywords internal
plot_reorder <- function(state, from, to) {
  from <- suppressWarnings(as.integer(from))
  to <- suppressWarnings(as.integer(to))
  if (length(from) != 1L || length(to) != 1L ||
      is.na(from) || is.na(to) || from == to) {
    return(invisible(FALSE))
  }
  pinned <- plot_pinned_order(state)
  start <- match(from, pinned)
  end <- match(to, pinned)
  if (is.na(start) || is.na(end)) return(invisible(FALSE))
  before <- undo_gallery_snapshot(state)
  moved <- pinned[start]
  rest <- pinned[-start]
  at <- end
  if (at > length(rest)) at <- length(rest)
  if (at < 1L) at <- 1L
  reordered <- append(rest, moved, after = at - 1L)
  for (position in seq_along(reordered)) {
    index <- reordered[[position]]
    state$plots[[index]]$order <- position
    state$plots[[index]]$index <- index
  }
  state_touch(state)
  undo_record(state, "gallery", tr("Reorder charts"), before,
              undo_gallery_snapshot(state))
  invisible(TRUE)
}

#' Move a pinned chart by one place
#' @keywords internal
plot_move <- function(state, key, delta) {
  index <- plot_locate(state, key)
  if (is.na(index)) return(invisible(FALSE))
  pinned <- plot_pinned_order(state)
  position <- match(index, pinned)
  if (is.na(position)) return(invisible(FALSE))
  target <- position + as.integer(delta)
  if (target < 1L || target > length(pinned)) return(invisible(FALSE))
  plot_reorder(state, index, pinned[[target]])
}

#' List the gallery
#'
#' @param state Application state.
#' @param query Free-text query matched against title, code, tags, type and
#'   data set.
#' @param type Optional chart type filter.
#' @param dataset Optional data set filter.
#' @param pinned When `TRUE`, only pinned plots are returned.
#' @return A data frame with one row per plot.
#' @keywords internal
plot_list <- function(state, query = NULL, type = NULL, dataset = NULL,
                      pinned = FALSE) {
  plots <- state$plots %||% list()
  if (length(plots) == 0L) {
    return(data.frame(
      index = integer(), id = character(), title = character(),
      type = character(), dataset = character(), time = character(),
      pinned = logical(), code = character(), url = character(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(seq_along(plots), function(index) {
    plot <- plots[[index]]
    type_id <- plot$spec$type %||% chart_type_from_code(plot$code)
    dataset_id <- plot$spec$dataset %||% ""
    data.frame(
      index = index,
      id = plot$id %||% sprintf("plot-%04d", index),
      title = plot_title(plot),
      type = type_id,
      dataset = dataset_id,
      time = format(plot$time %||% Sys.time(), "%Y-%m-%d %H:%M:%S"),
      pinned = isTRUE(plot$pinned),
      code = plot$code %||% "",
      url = plot$url %||% "",
      stringsAsFactors = FALSE
    )
  })
  table <- do.call(rbind, rows)

  if (!is.null(query) && nzchar(trimws(query))) {
    keep <- vapply(seq_len(nrow(table)), function(i) {
      grepl(tolower(trimws(query)),
            tolower(paste(table$title[[i]], table$code[[i]], table$type[[i]],
                          table$dataset[[i]])),
            fixed = TRUE)
    }, logical(1))
    table <- table[keep, , drop = FALSE]
  }
  if (!is.null(type) && nzchar(type) && !identical(type, "all")) {
    table <- table[table$type == type, , drop = FALSE]
  }
  if (!is.null(dataset) && nzchar(dataset)) {
    table <- table[table$dataset == dataset, , drop = FALSE]
  }
  if (isTRUE(pinned)) {
    table <- table[table$pinned, , drop = FALSE]
  }
  if (nrow(table) == 0L) return(table)
  orders <- vapply(plots, function(plot) {
    suppressWarnings(as.numeric(plot$order %||% plot$index %||% 0))
  }, numeric(1))
  sort_key <- ifelse(table$pinned, orders[table$index], -table$index)
  table[order(!table$pinned, sort_key), , drop = FALSE]
}

#' Update gallery metadata
#' @keywords internal
plot_update <- function(state, key, title = NULL, tags = NULL,
                        pinned = NULL) {
  index <- plot_locate(state, key)
  if (is.na(index)) return(invisible(FALSE))
  before <- undo_gallery_snapshot(state)
  plot <- state$plots[[index]]
  if (!is.null(title)) plot$title <- title
  if (!is.null(tags)) plot$tags <- tags
  if (!is.null(pinned)) plot$pinned <- isTRUE(pinned)
  state$plots[[index]] <- plot
  state_touch(state)
  label <- if (!is.null(pinned)) {
    if (isTRUE(pinned)) tr("Pin chart") else tr("Unpin chart")
  } else if (!is.null(title)) {
    tr("Rename chart")
  } else if (!is.null(tags)) {
    tr("Edit chart tags")
  } else {
    tr("Update chart")
  }
  undo_record(state, "gallery", label, before, undo_gallery_snapshot(state))
  invisible(TRUE)
}

#' Delete a plot from the gallery
#' @keywords internal
plot_delete <- function(state, key) {
  index <- plot_locate(state, key)
  if (is.na(index)) return(invisible(FALSE))
  before <- undo_gallery_snapshot(state)
  plot <- state$plots[[index]]
  if (!is.null(plot$file) && file.exists(plot$file)) unlink(plot$file)
  if (!is.null(plot$url) && !is.null(state$plot_dir) && !is.null(state$plot_prefix)) {
    name <- sub(paste0("^", state$plot_prefix, "/"), "", plot$url)
    path <- file.path(state$plot_dir, name)
    if (file.exists(path)) unlink(path)
  }
  state$plots <- state$plots[-index]
  state_touch(state)
  undo_record(state, "gallery", tr("Delete chart"), before,
              undo_gallery_snapshot(state))
  invisible(TRUE)
}

#' Return the specification attached to a plot
#' @keywords internal
plot_reopen <- function(state, key) {
  plot <- plot_entry(state, key)
  if (is.null(plot)) return(NULL)
  plot$spec
}

#' Interactive expression attached to a plot
#'
#' Chart Studio plots carry a specification; dialog plots carry the plotly
#' expression that the dialog returned.
#' @keywords internal
plot_interactive_code <- function(plot) {
  if (is.null(plot)) return(NULL)
  if (!is.null(plot$spec)) {
    code <- chart_spec_interactive(plot$spec)
    if (!is.null(code) && nzchar(code)) return(code)
  }
  code <- plot$interactive_code
  if (is.null(code) || !nzchar(code)) NULL else code
}

#' Two plots for side-by-side comparison
#' @keywords internal
plot_compare <- function(state, keys) {
  plots <- lapply(keys, function(key) plot_entry(state, key))
  Filter(Negate(is.null), plots)
}

#' Create a data set from selected plotly points
#'
#' @param state Application state.
#' @param spec Chart specification of the plot.
#' @param selected Data frame returned by `plotly::event_data()`.
#' @return A list with `ok`, `name`, `rows` and `command`.
#' @keywords internal
chart_subset_selected <- function(state, spec, selected) {
  if (is.null(selected) || nrow(selected) == 0L) {
    return(list(ok = FALSE,
                error = tr("Select points in an interactive scatterplot first.")))
  }
  if (is.null(spec)) {
    return(list(ok = FALSE, error = tr("The selected chart has no saved specification.")))
  }
  if (!identical(spec$type, "scatter") ||
      nzchar(spec$mapping$group %||% "")) {
    return(list(ok = FALSE, error = tr(
      "Subsetting from selection is available for ungrouped scatterplots."
    )))
  }
  rows <- as.integer(selected$pointNumber) + 1L
  rows <- rows[!is.na(rows)]
  if (length(rows) == 0L) {
    return(list(ok = FALSE, error = tr("Select points in an interactive scatterplot first.")))
  }
  name <- paste0(spec$dataset, "Selected")
  suffix <- 1L
  while (exists(name, envir = state$env, inherits = FALSE)) {
    suffix <- suffix + 1L
    name <- paste0(spec$dataset, "Selected", suffix)
  }
  command <- sprintf("%s <- %s[c(%s), , drop = FALSE]",
                     name, spec$dataset, paste(rows, collapse = ", "))
  outcome <- run_command(state, command, source = "chart")
  if (!identical(outcome$status, "ok")) {
    return(list(ok = FALSE,
                error = outcome$error %||% tr("The subset failed.")))
  }
  active_dataset(state, name)
  list(ok = TRUE, name = name, rows = length(rows), command = command)
}

#' Render a plot to a file
#'
#' @param state Application state.
#' @param key Plot index or identifier.
#' @param format One of `"png"`, `"pdf"`, `"svg"` or `"html"`.
#' @param file Destination path.
#' @param width,height,dpi Output size.
#' @return The path, invisibly.
#' @keywords internal
plot_export <- function(state, key, format = c("png", "pdf", "svg", "html"),
                        file, width = 800, height = 600, dpi = 96) {
  format <- match.arg(format)
  plot <- plot_entry(state, key)
  if (is.null(plot)) stop("The plot is not available.", call. = FALSE)

  if (identical(format, "html")) {
    if (!plotly_available()) {
      stop("The plotly package is required for HTML export.", call. = FALSE)
    }
    code <- plot_interactive_code(plot)
    if (is.null(code) || !nzchar(code)) {
      stop("This plot has no interactive version.", call. = FALSE)
    }
    widget <- plotly_build(state, code)
    if (is.null(widget)) stop("The interactive plot could not be built.",
                              call. = FALSE)
    htmlwidgets::saveWidget(widget, file, selfcontained = TRUE)
    return(invisible(file))
  }

  spec <- plot$spec
  if (!is.null(spec)) {
    code <- chart_spec_command(spec)
    switch(
      format,
      png = {
        grDevices::png(file, width = width, height = height, res = dpi)
        on.exit(grDevices::dev.off(), add = TRUE)
        eval(parse(text = code), envir = state$env)
      },
      pdf = {
        grDevices::pdf(file, width = width / 96, height = height / 96)
        on.exit(grDevices::dev.off(), add = TRUE)
        eval(parse(text = code), envir = state$env)
      },
      svg = {
        if (requireNamespace("svglite", quietly = TRUE)) {
          svglite::svglite(file, width = width / 96, height = height / 96)
        } else {
          grDevices::svg(file, width = width / 96, height = height / 96)
        }
        on.exit(grDevices::dev.off(), add = TRUE)
        eval(parse(text = code), envir = state$env)
      }
    )
    return(invisible(file))
  }

  # Legacy plots: reuse the captured PNG or replay the recorded plot.
  if (identical(format, "png")) {
    if (is.null(plot$file) || !file.exists(plot$file)) {
      stop("The plot file is not available.", call. = FALSE)
    }
    file.copy(plot$file, file, overwrite = TRUE)
    return(invisible(file))
  }
  if (is.null(plot$recorded)) {
    stop("The plot cannot be replayed.", call. = FALSE)
  }
  if (identical(format, "pdf")) {
    grDevices::pdf(file, width = width / 96, height = height / 96)
  } else {
    if (requireNamespace("svglite", quietly = TRUE)) {
      svglite::svglite(file, width = width / 96, height = height / 96)
    } else {
      grDevices::svg(file, width = width / 96, height = height / 96)
    }
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  grDevices::replayPlot(plot$recorded)
  invisible(file)
}

# Preview --------------------------------------------------------------------

chart_preview_cache_lookup <- function(key, width, height) {
  entries <- .chart_preview_cache$entries
  if (length(entries) == 0L) return(NULL)
  for (entry in entries) {
    if (identical(entry$key, key) && identical(entry$width, width) &&
        identical(entry$height, height)) {
      return(entry)
    }
  }
  NULL
}

chart_preview_cache_store <- function(entry, limit = 12L) {
  entries <- c(list(entry), .chart_preview_cache$entries)
  .chart_preview_cache$entries <- utils::head(entries, max(1L, limit))
  invisible(entry)
}

#' Clear the preview cache
#' @keywords internal
chart_preview_cache_clear <- function() {
  .chart_preview_cache$entries <- list()
  invisible(NULL)
}

#' Render an isolated chart preview
#'
#' The preview never logs a command and never adds a plot to the gallery.
#' Results are cached by specification and data set shape.
#' @keywords internal
chart_preview <- function(state, spec, width = NULL, height = NULL) {
  problems <- chart_spec_validate(spec, state)
  if (length(problems) > 0L) {
    return(list(
      type = "error", file = NULL, widget = NULL,
      error = paste(problems, collapse = " "), command = NULL
    ))
  }
  width <- as.integer(width %||% spec$size$width %||% 640L)
  height <- as.integer(height %||% spec$size$height %||% 420L)
  key <- paste(chart_spec_key(spec, state), state$revision %||% 0L, sep = "::")
  cached <- chart_preview_cache_lookup(key, width, height)
  if (!is.null(cached)) return(cached$result)

  code <- chart_spec_command(spec)
  packages <- required_packages(code)
  if (length(packages) > 0L) attach_packages(packages)
  rendered <- preview_plot(state, code, width = width, height = height)
  widget <- NULL
  if (plotly_available() && is.null(rendered$error)) {
    interactive <- chart_spec_interactive(spec)
    if (!is.null(interactive)) {
      # The builder uses its own plotly source so selection events do not mix
      # with the gallery detail.
      build_code <- gsub('source = "rcmdr-chart"', 'source = "rcmdr-build"',
                         interactive, fixed = TRUE)
      widget <- preview_plotly(state, build_code)$widget
    }
  }
  result <- list(
    type = if (is.null(rendered$error)) "image" else "error",
    file = rendered$file,
    widget = widget,
    error = rendered$error,
    command = code,
    output = rendered$output
  )
  chart_preview_cache_store(
    list(key = key, width = width, height = height, result = result),
    limit = state$options$chart_preview_cache %||% 12L
  )
  result
}

#' Apply a chart specification
#'
#' Runs the generated command through [run_command()], attaches the spec to the
#' resulting plot and returns the gallery index.
#' @keywords internal
chart_apply <- function(state, spec, source = "chart") {
  problems <- chart_spec_validate(spec, state)
  if (length(problems) > 0L) {
    return(list(ok = FALSE, error = paste(problems, collapse = " ")))
  }
  command <- chart_spec_command(spec)
  before <- length(state$plots)
  outcome <- tryCatch(
    run_command(
      state, command, plot = "auto", source = source,
      dialog_id = "chartStudio"
    ),
    error = function(e) list(status = "error", error = conditionMessage(e))
  )
  if (!identical(outcome$status, "ok")) {
    return(list(
      ok = FALSE,
      error = outcome$error %||% tr("The chart command failed."),
      command = command
    ))
  }
  index <- length(state$plots)
  if (index > before) {
    plot <- state$plots[[index]]
    spec$id <- plot$id
    plot$spec <- spec
    plot$title <- plot_title(list(spec = spec))
    plot$tags <- unique(c(plot$tags %||% character(), "chart", spec$type,
                          spec$dataset %||% ""))
    state$plots[[index]] <- plot
    state$chart_last_spec <- spec
    state$chart_selection <- NULL
  }
  state_touch(state)
  list(ok = TRUE, index = index, command = command)
}

# UI -------------------------------------------------------------------------

#' Chart Studio toolbar and mode switch
#' @keywords internal
chart_studio_ui <- function(show_preview = TRUE) {
  htmltools::tagList(
    toolbar(
      segmented_input(
        "chart_mode", NULL,
        stats::setNames(
          c("build", "models", "gallery"),
          c(tr("Build"), tr("Models"), tr("Gallery"))
        ),
        selected = "build"
      ),
      label = tr("Chart Studio")
    ),
    note(tr(
      "Create a chart, preview its command, then apply it to the gallery."
    )),
    conditionalPanel(
      "input.chart_mode === 'build' || input.chart_mode === null",
      chart_builder_ui(show_preview = show_preview)
    ),
    conditionalPanel(
      "input.chart_mode === 'models'",
      chart_models_ui()
    ),
    conditionalPanel(
      "input.chart_mode === 'gallery'",
      chart_gallery_ui()
    ),
    htmltools::div(
      class = "visually-hidden",
      downloadButton("chart_download_png", tr("Download PNG")),
      downloadButton("chart_download_pdf", tr("Download PDF")),
      downloadButton("chart_download_svg", tr("Download SVG")),
      downloadButton("chart_download_html", tr("Download HTML"))
    )
  )
}

#' Accordion of the per-type options
#'
#' The dynamic options (two to seven per type) get the same hierarchy as the
#' static ones.  The id is stable, so the server reads which groups are open
#' and keeps them open across a type change: a group that survives the change
#' stays open, a group that disappears is simply absent.
#'
#' @param info Chart type descriptor.
#' @param spec Chart specification.
#' @param open Group values the client had open.
#' @return A `div` tag.
#' @keywords internal
chart_options_accordion <- function(info, spec, open = NULL) {
  groups <- chart_option_controls(info, spec)
  available <- names(groups)
  open <- intersect(as.character(open %||% character(0)), available)
  if (length(open) == 0L) open <- available[[1L]]
  panels <- lapply(available, function(value) {
    settings_panel(tr(value), groups[[value]], value = value)
  })
  do.call(settings_accordion, c(panels, list(
    id = "chart_type_options",
    open = open,
    level = 4L,
    class = "rcmdr-accordion-nested"
  )))
}

#' Builder panel
#' @keywords internal
chart_builder_ui <- function(show_preview = TRUE) {
  split_pane(
    "chart_layout",
    htmltools::div(
      class = "rcmdr-chart-builder",
      # The identity of the chart stays in view: type, data set, mapping and
      # composition are the four answers a chart cannot do without.
      htmltools::div(
        class = "rcmdr-section-card rcmdr-chart-identity",
        htmltools::tags$h6(tr("Chart")),
        selectInput(
          "chart_type", tr("Chart type"),
          choices = chart_type_choices_by_analysis(), selected = "histogram",
          width = "100%"
        ),
        uiOutput("chart_dataset_ui"),
        uiOutput("chart_mapping_ui"),
        uiOutput("chart_compose_ui"),
        help_text(tr(
          "The mapping fields change with the chart type. The last button opens the matching classic Rcmdr dialog."
        ))
      ),
      # Everything else is one line away.  Values are stable English keys so
      # the open state survives a language change and a re-render.
      settings_accordion(
        id = "chart_settings",
        open = "Options",
        settings_panel(
          tr("Options"),
          uiOutput("chart_options_ui"),
          value = "Options"
        ),
        settings_panel(
          tr("Style"),
          selectInput(
            "chart_gg_position", tr("Position"),
            choices = stats::setNames(
              c("identity", "dodge", "stack", "fill"),
              c("Identity", "Dodge", "Stack", "Fill")
            ),
            selected = "identity"
          ),
          field(
            slider_input("chart_gg_alpha", tr("Alpha"), 0, 1, 0.7, 0.05),
            help = help_tip(tr(
              "Alpha sets how transparent the marks are: 0 is invisible, 1 is solid."
            ))
          ),
          number_input("chart_gg_binwidth", tr("Bin width (0 = auto)"), 0,
                       min = 0, step = 0.1),
          field(
            slider_input("chart_gg_jitter", tr("Jitter (0 = off)"), 0, 0.5,
                         0, 0.05),
            help = help_tip(tr(
              "Jitter spreads overlapping points; it does not change the data."
            ))
          ),
          number_input("chart_gg_shape", tr("Point shape"), 19,
                       min = 0, max = 25, step = 1),
          selectInput(
            "chart_gg_smooth", tr("Smooth"),
            choices = stats::setNames(
              c("lm", "loess", "gam"),
              c("Linear", "LOESS", "GAM")
            ),
            selected = "lm"
          ),
          checkboxInput("chart_gg_se", tr("Confidence band"), FALSE),
          checkboxInput("chart_gg_flip", tr("Flip coordinates"), FALSE),
          value = "Style"
        ),
        settings_panel(
          tr("Axes"),
          selectInput(
            "chart_gg_x_format", tr("X axis format"),
            choices = chart_axis_format_choices(), selected = "auto"
          ),
          selectInput(
            "chart_gg_y_format", tr("Y axis format"),
            choices = chart_axis_format_choices(), selected = "auto"
          ),
          field(
            selectInput(
              "chart_gg_facet_scales", tr("Facet scales"),
              choices = stats::setNames(
                c("fixed", "free", "free_x", "free_y"),
                c("Fixed", "Free", "Free X", "Free Y")
              ),
              selected = "fixed"
            ),
            help = help_tip(tr(
              "Facet scales let each panel keep its own axis range."
            ))
          ),
          number_input("chart_gg_facet_ncol", tr("Facet columns (0 = auto)"),
                       0, min = 0, step = 1),
          checkboxInput("chart_gg_polar", tr("Polar coordinates"), FALSE),
          selectInput(
            "chart_gg_polar_theta", tr("Polar angle"),
            choices = stats::setNames(c("x", "y"), c("X", "Y")),
            selected = "x"
          ),
          value = "Axes"
        ),
        settings_panel(
          tr("Text"),
          htmltools::div(
            class = "rcmdr-field-wide",
            textInput("chart_title", tr("Title"), "")
          ),
          htmltools::div(
            class = "rcmdr-field-wide",
            textInput("chart_caption", tr("Caption"), "")
          ),
          textInput("chart_xlab", tr("X label"), ""),
          textInput("chart_ylab", tr("Y label"), ""),
          textInput("chart_gg_subtitle", tr("Subtitle"), ""),
          textInput("chart_gg_tag", tr("Tag"), ""),
          slider_input("chart_base_size", tr("Base size"), 6, 32, 12, 1),
          value = "Text"
        ),
        settings_panel(
          tr("Theme"),
          selectInput(
            "chart_gg_theme", tr("ggplot2 theme"),
            choices = chart_gg_theme_choices(),
            selected = "minimal"
          ),
          selectInput("chart_palette", tr("Palette"),
                      choices = chart_palette_choices(),
                      selected = "default"),
          selectInput(
            "chart_legend", tr("Legend"),
            choices = stats::setNames(
              c("right", "left", "top", "bottom", "none"),
              c(tr("Right"), tr("Left"), tr("Top"), tr("Bottom"),
                tr("None"))
            ),
            selected = "right"
          ),
          color_input("chart_background", tr("Background")),
          checkboxInput("chart_grid", tr("Grid"), value = TRUE),
          value = "Theme"
        ),
        settings_panel(
          tr("Output"),
          number_input("chart_width", tr("Width (px)"), 800,
                       min = 200, max = 4000, step = 50),
          number_input("chart_height", tr("Height (px)"), 600,
                       min = 150, max = 4000, step = 50),
          if (!requireNamespace("ggplot2", quietly = TRUE)) {
            help_text(tr(
              "Install ggplot2 to enable the Chart Studio."
            ))
          },
          value = "Output"
        )
      )
    ),
    if (isTRUE(show_preview)) htmltools::div(
      class = "rcmdr-chart-preview-column",
      htmltools::div(
        class = "rcmdr-section-card rcmdr-chart-preview",
        htmltools::tags$h6(tr("Preview")),
        uiOutput("chart_preview_message"),
        htmltools::div(
          class = "rcmdr-chart-preview-image",
          uiOutput("chart_preview_media")
        ),
        uiOutput("chart_preview_selection"),
        htmltools::tags$h6(class = "rcmdr-section-subhead",
                           tr("Generated command")),
        verbatimTextOutput("chart_command_text")
      ),
      action_row(
        actionButton("chart_preview", tr("Refresh preview"),
                     class = "btn-sm btn-primary"),
        actionButton("chart_apply", tr("Apply"),
                     class = "btn-sm btn-success"),
        actionButton("chart_reset", tr("Reset"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("chart_advanced",
                     tr("Open in the classic dialog (base R code)"),
                     class = "btn-sm btn-outline-primary")
      )
    ),
    class = "rcmdr-chart-layout",
    initial = 5 / 12,
    min = 300,
    min_second = 320
  )
}

#' Gallery panel
#' @keywords internal
chart_gallery_ui <- function() {
  htmltools::tagList(
    toolbar(
      left = htmltools::div(
        class = "rcmdr-toolbar-fields",
        htmltools::div(
          class = "rcmdr-toolbar-field rcmdr-toolbar-field-wide",
          textInput("chart_gallery_query", NULL,
                    placeholder = tr("Search charts..."))
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_gallery_analysis", NULL,
            choices = c(stats::setNames("all", tr("All analyses")),
                        chart_analysis_levels())
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_gallery_type", NULL,
            choices = c(stats::setNames("all", tr("All types")),
                        chart_type_choices())
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field",
          checkboxInput("chart_gallery_pinned",
                        tr("Pinned only"), value = FALSE)
        )
      ),
      right = action_row(
        tight = TRUE,
        actionButton("chart_gallery_refresh", tr("Refresh"),
                     class = "btn-sm btn-outline-secondary"),
        actionButton("chart_selection_subset",
                     tr("Subset selected points"),
                     class = "btn-sm btn-outline-primary")
      ),
      label = tr("Gallery")
    ),
    note(tr(
      "Drag a pinned chart onto another to change their order; right-click a card for actions."
    )),
    uiOutput("chart_gallery_grid"),
    uiOutput("chart_detail")
  )
}

chart_action_link <- function(label, index, action,
                              class = "btn btn-sm btn-outline-secondary") {
  htmltools::tags$a(
    href = "#", class = class,
    onclick = sprintf(
      "Shiny.setInputValue('chart_action', {index: %d, action: '%s'}, {priority: 'event'}); return false;",
      as.integer(index), action
    ),
    label
  )
}

chart_copy_link <- function(plot, label = NULL) {
  htmltools::tags$a(
    href = "#", class = "btn btn-sm btn-outline-secondary",
    `data-code` = plot$code %||% "",
    onclick = "rcmdrCopy(this.getAttribute('data-code')); return false;",
    label %||% tr("Copy code")
  )
}

#' Gallery cards
#' @keywords internal
chart_gallery_ui_cards <- function(table) {
  if (is.null(table) || nrow(table) == 0L) {
    return(empty_state(
      tr("No charts yet"),
      tr("Build a chart and press Apply to add it to the gallery.")
    ))
  }
  htmltools::div(
    class = "rcmdr-chart-grid",
    lapply(seq_len(nrow(table)), function(i) {
      row <- table[i, , drop = FALSE]
      plot <- list(
        title = row$title, code = row$code, url = row$url,
        pinned = row$pinned, tags = character()
      )
      menu_id <- sprintf("chart_card_menu_%d", as.integer(row$index))
      htmltools::tagList(
        context_menu_target(
          class = paste("rcmdr-chart-card", if (row$pinned) "pinned"),
          menu = menu_id,
          payload = sprintf('{"index":%d}', as.integer(row$index)),
          label = sprintf("%s: %s", tr("Chart actions"), row$title),
          extra = list(
            `data-rcmdr-sortable` = "chart",
            `data-rcmdr-sortable-id` = as.character(as.integer(row$index)),
            draggable = if (isTRUE(row$pinned)) "true" else NULL
          ),
          htmltools::div(
            class = "rcmdr-chart-thumb",
            onclick = sprintf(
              "Shiny.setInputValue('chart_action', {index: %d, action: 'detail'}, {priority: 'event'});",
              row$index
            ),
            if (nzchar(row$url)) {
              htmltools::tags$img(src = row$url, alt = row$title)
            } else {
              htmltools::div(class = "rcmdr-chart-thumb-empty",
                             tr("No preview"))
            }
          ),
          htmltools::div(
            class = "rcmdr-chart-card-body",
            htmltools::tags$h6(row$title),
            note(sprintf("%s - %s", row$type %||% "", row$time)),
            action_row(
              tight = TRUE,
              chart_action_link(tr("Detail"), row$index, "detail",
                                "btn btn-sm btn-outline-primary"),
              chart_action_link(
                if (isTRUE(row$pinned)) tr("Unpin") else tr("Pin"),
                row$index, "pin", "btn btn-sm btn-outline-secondary"
              ),
              chart_action_link(tr("Reopen"), row$index, "reopen",
                                "btn btn-sm btn-outline-secondary"),
              chart_copy_link(plot)
            )
          )
        ),
        context_menu(
          menu_id,
          context_menu_item(tr("Detail"), input = "chart_action",
                            action = "detail"),
          context_menu_item(
            if (isTRUE(row$pinned)) tr("Unpin") else tr("Pin"),
            input = "chart_action", action = "pin"
          ),
          context_menu_item(tr("Reopen"), input = "chart_action",
                            action = "reopen"),
          if (isTRUE(row$pinned)) {
            context_menu_separator()
          },
          if (isTRUE(row$pinned)) {
            context_menu_item(tr("Move earlier"), input = "chart_order",
                              action = "up")
          },
          if (isTRUE(row$pinned)) {
            context_menu_item(tr("Move later"), input = "chart_order",
                              action = "down")
          },
          context_menu_separator(),
          context_menu_item(tr("Rename"), input = "chart_action",
                            action = "rename"),
          context_menu_item(tr("Delete"), input = "chart_action",
                            action = "delete", danger = TRUE),
          label = tr("Chart actions")
        )
      )
    })
  )
}

#' Models gallery
#' @keywords internal
chart_models_ui <- function() {
  htmltools::tagList(
    toolbar(
      left = htmltools::div(
        class = "rcmdr-toolbar-fields",
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_models_analysis", NULL,
            choices = c(stats::setNames("all", tr("All analyses")),
                        chart_analysis_levels())
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_models_type", NULL,
            choices = c(stats::setNames("all", tr("All types")),
                        chart_type_choices())
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field rcmdr-toolbar-field-wide",
          textInput("chart_models_query", NULL,
                    placeholder = tr("Search models..."))
        )
      ),
      label = tr("Models")
    ),
    note(tr("Open a model, then pick the variables.")),
    uiOutput("chart_models_grid")
  )
}

chart_model_action_link <- function(id, label) {
  htmltools::tags$a(
    href = "#", class = "btn btn-sm btn-outline-primary",
    onclick = sprintf(
      "Shiny.setInputValue('chart_model_action', {id: '%s'}, {priority: 'event'}); return false;",
      id
    ),
    label
  )
}

#' Model cards
#' @keywords internal
chart_models_cards <- function(table) {
  if (is.null(table) || nrow(table) == 0L) {
    return(empty_state(
      tr("No models match the filters"),
      tr("Clear the search or choose another analysis family.")
    ))
  }
  htmltools::div(
    class = "rcmdr-chart-grid",
    lapply(seq_len(nrow(table)), function(i) {
      row <- table[i, , drop = FALSE]
      htmltools::div(
        class = paste("rcmdr-chart-card", if (!row$installed) "disabled"),
        htmltools::div(
          class = "rcmdr-chart-card-body",
          htmltools::tags$h6(row$label),
          note(sprintf("%s - %s", chart_analysis_label(row$analysis),
                       row$type_label)),
          note(row$description),
          action_row(
            tight = TRUE,
            if (isTRUE(row$installed)) {
              chart_model_action_link(row$id, tr("Open"))
            } else {
              badge(sprintf(tr("%s missing"), row$requires), "warning")
            }
          )
        )
      )
    })
  )
}

#' Gallery detail
#' @keywords internal
chart_detail_ui <- function(plot, index) {
  if (is.null(plot)) {
    return(empty_state(
      tr("Select a chart"),
      tr("Choose a thumbnail to see its preview, metadata and actions.")
    ))
  }
  spec <- plot$spec
  htmltools::div(
    class = "rcmdr-chart-detail",
    card_head(
      htmltools::div(
        class = "rcmdr-chart-detail-title",
        htmltools::tags$h5(plot_title(plot)),
        note(sprintf(
          "%s - %s - %s",
          spec$type %||% chart_type_from_code(plot$code),
          spec$dataset %||% tr("unknown data set"),
          format(plot$time %||% Sys.time(), "%Y-%m-%d %H:%M:%S")
        ))
      ),
      action_row(
        tight = TRUE,
        chart_action_link(tr("Reopen in builder"), index, "reopen",
                          "btn btn-sm btn-primary"),
        chart_action_link(tr("Rename"), index, "rename",
                          "btn btn-sm btn-outline-secondary"),
        chart_action_link(if (isTRUE(plot$pinned)) tr("Unpin") else tr("Pin"),
                          index, "pin",
                          "btn btn-sm btn-outline-secondary"),
        chart_action_link(tr("Export..."), index, "export",
                          "btn btn-sm btn-outline-secondary"),
        chart_action_link(tr("Delete"), index, "delete",
                          "btn btn-sm btn-outline-danger"),
        chart_copy_link(plot),
        chart_action_link(tr("Add to report"), index, "report",
                          "btn btn-sm btn-outline-secondary")
      )
    ),
    if (!is.null(plot$url) && nzchar(plot$url)) {
      htmltools::tags$img(
        class = "rcmdr-chart-detail-image", src = plot$url,
        alt = plot_title(plot)
      )
    },
    shiny::uiOutput("chart_detail_plotly_ui"),
    htmltools::tags$h6(tr("Command")),
    htmltools::tags$pre(class = "rcmdr-pre", plot$code %||% ""),
    if (!is.null(spec)) {
      htmltools::tagList(
        htmltools::tags$h6(tr("Specification")),
        htmltools::tags$pre(
          class = "rcmdr-pre",
          paste(utils::capture.output(utils::str(spec[c(
            "type", "dataset", "mapping", "options", "theme", "labels"
          )])), collapse = "\n")
        )
      )
    }
  )
}

# Dialogs --------------------------------------------------------------------

chart_rename_dialog <- function() {
  id <- "chartRename"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Rename chart"), help = "plot", preview = FALSE,
    ui = function(state, memory) {
      index <- memory$index %||% 0L
      plot <- plot_entry(state, index)
      title <- memory$title %||% if (!is.null(plot)) plot_title(plot) else ""
      htmltools::tagList(
        htmltools::div(
          style = "display: none;",
          textInput(ns("index"), NULL, value = as.character(index))
        ),
        entry_input(ns("title"), tr("Chart title"), title)
      )
    },
    on_ok = function(input, state) {
      index <- as.integer(input[[ns("index")]] %||% 0L)
      title <- trim_blanks(input[[ns("title")]] %||% "")
      if (!nzchar(title)) return(list(error = tr("Enter a chart title.")))
      if (!plot_update(state, index, title = title)) {
        return(list(error = tr("The chart is not available.")))
      }
      list(
        message = tr("Chart renamed."),
        memory = list(index = index, title = title)
      )
    }
  )
}

chart_delete_dialog <- function() {
  id <- "chartDelete"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Delete chart"), help = "plot", preview = FALSE,
    ui = function(state, memory) {
      index <- memory$index %||% 0L
      plot <- plot_entry(state, index)
      htmltools::tagList(
        htmltools::div(
          style = "display: none;",
          textInput(ns("index"), NULL, value = as.character(index))
        ),
        htmltools::tags$p(sprintf(
          tr("Delete \"%s\" from the gallery?"),
          if (!is.null(plot)) plot_title(plot) else tr("this chart")
        )),
        help_text(tr(
          "The command stays in the log and in the structured history."
        ))
      )
    },
    on_ok = function(input, state) {
      index <- as.integer(input[[ns("index")]] %||% 0L)
      if (!plot_delete(state, index)) {
        return(list(error = tr("The chart is not available.")))
      }
      list(message = tr("Chart deleted."))
    }
  )
}

chart_export_dialog <- function() {
  id <- "chartExport"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Export chart"), help = "plot", preview = FALSE,
    ui = function(state, memory) {
      index <- memory$index %||% 0L
      plot <- plot_entry(state, index)
      formats <- c("PNG" = "png", "PDF" = "pdf")
      if (requireNamespace("svglite", quietly = TRUE)) {
        formats <- c(formats, "SVG" = "svg")
      }
      if (!is.null(plot_interactive_code(plot))) {
        formats <- c(formats, "HTML" = "html")
      }
      htmltools::tagList(
        htmltools::div(
          style = "display: none;",
          textInput(ns("index"), NULL, value = as.character(index))
        ),
        htmltools::tags$p(sprintf(
          tr("Export \"%s\"."),
          if (!is.null(plot)) plot_title(plot) else tr("this chart")
        )),
        radio_input(ns("format"), tr("Format"), formats,
                    memory$format %||% "png"),
        field_grid(
          number_input(ns("width"), tr("Width (px)"), 800,
                       min = 200, max = 4000, step = 50),
          number_input(ns("height"), tr("Height (px)"), 600,
                       min = 150, max = 4000, step = 50),
          number_input(ns("dpi"), tr("DPI"), 96,
                       min = 72, max = 600, step = 12)
        )
      )
    },
    on_ok = function(input, state) {
      index <- as.integer(input[[ns("index")]] %||% 0L)
      plot <- plot_entry(state, index)
      if (is.null(plot)) return(list(error = tr("The chart is not available.")))
      format <- input[[ns("format")]] %||% "png"
      state$chart_export_request <- list(
        index = index,
        format = format,
        width = as.integer(input[[ns("width")]] %||% 800),
        height = as.integer(input[[ns("height")]] %||% 600),
        dpi = as.integer(input[[ns("dpi")]] %||% 96)
      )
      request_download(state, paste0("chart_download_", format))
      list(
        message = tr("The chart is being exported."),
        memory = list(index = index, format = format,
                      width = state$chart_export_request$width,
                      height = state$chart_export_request$height,
                      dpi = state$chart_export_request$dpi)
      )
    }
  )
}

#' Chart Studio dialog catalogue
#' @keywords internal
chart_studio_dialogs <- function() {
  list(
    chartRename = chart_rename_dialog(),
    chartDelete = chart_delete_dialog(),
    chartExport = chart_export_dialog()
  )
}

# Server ---------------------------------------------------------------------

#' Chart Studio server
#'
#' Wires the builder, the live preview, the apply action and the gallery to the
#' shared application state.
#' @keywords internal
chart_studio_server <- function(input, output, session, state, chart_revision,
                                refresh, tick = NULL) {
  chart_env <- new.env(parent = emptyenv())
  chart_env$pending <- NULL

  app_tick <- function() {
    if (is.function(tick)) tick() else NULL
  }

  chart_detail_index <- reactiveVal(NULL)
  chart_selection <- reactiveVal(NULL)

  chart_spec_from_inputs <- function() {
    type <- input$chart_type %||% "histogram"
    info <- chart_type(type)
    if (is.null(info)) return(NULL)
    slots <- chart_mapping_slots(info, "ggplot2", type)

    dataset <- input$chart_dataset %||% active_dataset(state)
    mapping <- lapply(names(slots), function(slot) {
      value <- input[[paste0("chart_map_", slot)]]
      if (is.null(value)) NULL else value
    })
    names(mapping) <- names(slots)

    option_names <- names(info$defaults %||% list())
    options <- lapply(option_names, function(name) {
      value <- input[[paste0("chart_opt_", name)]]
      if (is.null(value)) NULL else value
    })
    names(options) <- option_names
    options <- Filter(Negate(is.null), options)
    gg <- list(
      alpha = input$chart_gg_alpha %||% 0.7,
      position = input$chart_gg_position %||% "identity",
      binwidth = input$chart_gg_binwidth %||% 0,
      smooth_method = input$chart_gg_smooth %||% "lm",
      smooth_se = isTRUE(input$chart_gg_se),
      jitter = input$chart_gg_jitter %||% 0,
      flip = isTRUE(input$chart_gg_flip),
      facet_scales = input$chart_gg_facet_scales %||% "fixed",
      facet_ncol = input$chart_gg_facet_ncol %||% 0,
      shape = input$chart_gg_shape %||% 19,
      x_format = input$chart_gg_x_format %||% "auto",
      y_format = input$chart_gg_y_format %||% "auto",
      polar = isTRUE(input$chart_gg_polar),
      polar_theta = input$chart_gg_polar_theta %||% "x"
    )
    options <- utils::modifyList(options, gg)

    if (identical(type, "compose")) {
      plots <- state$plots %||% list()
      indices <- suppressWarnings(as.integer(input$chart_compose_plots %||%
                                              integer()))
      indices <- indices[!is.na(indices) & indices >= 1L &
                           indices <= length(plots)]
      children <- lapply(plots[indices], function(plot) plot$spec)
      children <- Filter(function(child) {
        is.list(child) && !identical(child$type %||% "", "compose")
      }, children)
      options$children <- unname(children)
      mapping <- list()
    }

    labels <- list(
      title = input$chart_title %||% "",
      subtitle = input$chart_gg_subtitle %||% "",
      x = input$chart_xlab %||% "",
      y = input$chart_ylab %||% "",
      caption = input$chart_caption %||% "",
      tag = input$chart_gg_tag %||% ""
    )
    theme <- list(
      engine = "ggplot2",
      palette = input$chart_palette %||% "default",
      base_size = as.numeric(input$chart_base_size %||% 12),
      grid = isTRUE(input$chart_grid %||% TRUE),
      legend = input$chart_legend %||% "right",
      background = input$chart_background %||% "white",
      ggplot_theme = input$chart_gg_theme %||% "minimal"
    )
    size <- list(
      width = as.integer(input$chart_width %||% 800),
      height = as.integer(input$chart_height %||% 600),
      dpi = 96L
    )

    tryCatch(
      chart_spec(
        type = type, dataset = dataset, mapping = mapping,
        options = options, theme = theme, labels = labels, size = size
      ),
      error = function(e) NULL
    )
  }

  chart_current_spec <- reactive({
    chart_spec_from_inputs()
  })


  output$chart_dataset_ui <- renderUI({
    chart_revision()
    registry <- dataset_registry(state)
    if (nrow(registry) == 0L) {
      return(help_text(tr("There are no data sets in the session.")))
    }
    labels <- sprintf("%s (%d x %d)", registry$name, registry$rows,
                      registry$cols)
    selected <- isolate(input$chart_dataset %||% active_dataset(state))
    if (is.null(selected) || !selected %in% registry$name) {
      selected <- if (!is.null(active_dataset(state))) {
        active_dataset(state)
      } else registry$name[[1L]]
    }
    selectInput(
      "chart_dataset", tr("Data set"),
      choices = stats::setNames(registry$name, labels),
      selected = selected, width = "100%"
    )
  })

  chart_mapping_spec <- function() {
    type <- input$chart_type %||% "histogram"
    info <- chart_type(type)
    if (is.null(info)) return(NULL)
    slots <- chart_mapping_slots(info, "ggplot2", type)
    dataset <- input$chart_dataset %||% active_dataset(state)
    mapping <- lapply(names(slots), function(slot) {
      input[[paste0("chart_map_", slot)]]
    })
    names(mapping) <- names(slots)
    chart_spec(type = type, dataset = dataset, mapping = mapping)
  }

  output$chart_mapping_ui <- renderUI({
    input$chart_type
    input$chart_dataset
    chart_revision()
    spec <- chart_mapping_spec()
    if (is.null(spec)) return(NULL)
    chart_mapping_controls(state, spec, chart_env$pending)
  })

  output$chart_compose_ui <- renderUI({
    if (!identical(input$chart_type, "compose")) return(NULL)
    chart_revision()
    app_tick()
    plots <- state$plots %||% list()
    if (length(plots) < 2L) {
      return(help_text(tr(
        "Apply at least two charts first: the composition combines gallery charts."
      )))
    }
    titles <- vapply(seq_along(plots), function(i) {
      sprintf("%d. %s", i, plot_title(plots[[i]]))
    }, character(1))
    selected <- chart_env$compose_selection %||%
      as.character(seq_len(min(2L, length(plots))))
    selected <- as.character(selected)
    selected <- selected[selected %in% as.character(seq_along(plots))]
    checkboxGroupInput(
      "chart_compose_plots", tr("Charts to combine"),
      choiceNames = titles,
      choiceValues = as.character(seq_along(plots)),
      selected = selected, width = "100%"
    )
  })

  observeEvent(input$chart_compose_plots, {
    chart_env$compose_selection <- input$chart_compose_plots
  }, ignoreInit = TRUE)

  output$chart_models_grid <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "models"))
    table <- chart_model_table(
      analysis = input$chart_models_analysis %||% "all",
      type = input$chart_models_type %||% "all",
      query = input$chart_models_query %||% ""
    )
    chart_models_cards(table)
  })

  observeEvent(input$chart_model_action, {
    id <- input$chart_model_action$id %||% ""
    model <- chart_model(id)
    if (is.null(model)) return()
    if (!chart_ext_available(model$requires)) {
      showNotification(
        sprintf(
          tr("This model needs the %s package. %s"),
          paste(model$requires, collapse = ", "),
          chart_ext_hint(model$requires)
        ),
        type = "message", duration = 10
      )
      return()
    }
    chart_env$pending <- chart_model_spec(model,
                                          input$chart_dataset %||%
                                            active_dataset(state))
    updateRadioButtons(session, "chart_mode", selected = "build")
    updateSelectInput(session, "chart_type",
                      choices = chart_type_choices_by_analysis(),
                      selected = model$type)
    theme <- model$theme %||% list()
    if (!is.null(theme$ggplot_theme)) {
      updateSelectInput(session, "chart_gg_theme",
                        choices = chart_gg_theme_choices(),
                        selected = theme$ggplot_theme)
    }
    for (name in names(model$options %||% list())) {
      input_id <- chart_option_input_id(name)
      value <- model$options[[name]]
      if (is.logical(value)) {
        updateCheckboxInput(session, input_id, value = value)
      } else if (is.numeric(value)) {
        update_number_input(session, input_id, value)
      } else {
        updateSelectInput(session, input_id, selected = as.character(value))
      }
    }
    chart_preview_cache_clear()
    chart_revision(chart_revision() + 1L)
    showNotification(sprintf(tr("Model loaded: %s"), model$label),
                     type = "message", duration = 4)
  }, ignoreInit = TRUE)

  chart_options_spec <- function() {
    type <- input$chart_type %||% "histogram"
    info <- chart_type(type)
    if (is.null(info)) return(NULL)
    options <- lapply(names(info$defaults %||% list()), function(name) {
      input[[paste0("chart_opt_", name)]]
    })
    names(options) <- names(info$defaults %||% list())
    options <- Filter(Negate(is.null), options)
    chart_spec(type = type, options = options)
  }

  output$chart_options_ui <- renderUI({
    input$chart_type
    spec <- chart_options_spec()
    if (is.null(spec)) return(NULL)
    if (!is.null(chart_env$pending) &&
        identical(chart_env$pending$type, spec$type)) {
      spec$options <- utils::modifyList(
        spec$options, chart_env$pending$options %||% list()
      )
    }
    info <- chart_type(spec$type)
    # Read the open groups with isolate(): the render depends on the type, not
    # on the accordion state, so opening a panel cannot re-render the panel.
    chart_options_accordion(
      info, spec, open = isolate(input$chart_type_options)
    )
  })

  output$chart_command_text <- renderText({
    spec <- chart_current_spec()
    if (is.null(spec)) return("")
    tryCatch(chart_spec_command(spec), error = function(e) conditionMessage(e))
  })

  chart_preview_spec <- debounce(reactive(chart_current_spec()), 350)
  chart_build_selection <- reactiveVal(NULL)
  chart_build_interactive_ready <- reactiveVal(FALSE)

  chart_preview_result <- reactive({
    spec <- chart_preview_spec()
    if (is.null(spec)) return(NULL)
    chart_preview(
      state, spec,
      width = isolate(input$chart_width %||% 800),
      height = isolate(input$chart_height %||% 600)
    )
  })

  output$chart_preview_media <- renderUI({
    result <- chart_preview_result()
    height <- isolate(input$chart_height %||% 600)
    if (!is.null(result$widget)) {
      plotly::plotlyOutput("chart_preview_plotly",
                           height = paste0(height, "px"))
    } else {
      imageOutput("chart_preview_image", height = "auto")
    }
  })

  output$chart_preview_plotly <- plotly::renderPlotly({
    result <- chart_preview_result()
    req(result$widget)
    chart_build_interactive_ready(TRUE)
    result$widget
  })

  output$chart_preview_image <- renderImage({
    result <- chart_preview_result()
    src <- result$file %||% NULL
    if (is.null(src) || length(src) != 1L || is.na(src) ||
        !nzchar(src) || !file.exists(src)) {
      return(NULL)
    }
    list(
      src = src,
      contentType = "image/png",
      width = isolate(input$chart_width %||% 800),
      height = isolate(input$chart_height %||% 600),
      alt = tr("Chart preview")
    )
  }, deleteFile = FALSE)

  output$chart_preview_message <- renderUI({
    result <- chart_preview_result()
    if (is.null(result)) {
      return(help_text(tr("Choose a chart type and a variable to see the preview.")))
    }
    if (!is.null(result$error)) {
      return(htmltools::tags$div(
        class = "alert alert-warning rcmdr-alert-compact",
        sprintf(tr("Preview: %s"), result$error)
      ))
    }
    help_text(tr(
      "The preview is isolated: it does not run a command and does not add a plot to the gallery."
    ))
  })

  output$chart_preview_selection <- renderUI({
    selected <- chart_build_selection()
    if (is.null(selected) || nrow(selected) == 0L) return(NULL)
    spec <- chart_current_spec()
    rows <- nrow(selected)
    if (is.null(spec) || !identical(spec$type, "scatter") ||
        nzchar(spec$mapping$group %||% "")) {
      return(help_text(sprintf(
        tr("%d point(s) selected. Subsetting is available for ungrouped scatterplots."),
        rows
      )))
    }
    action_row(
      tight = TRUE,
      note(sprintf(tr("%d point(s) selected."), rows), inline = TRUE),
      actionButton("chart_build_subset",
                   tr("Create data set from selection"),
                   class = "btn-sm btn-outline-primary")
    )
  })

  if (plotly_available()) {
    observeEvent(chart_build_interactive_ready(), {
      observeEvent(
        plotly::event_data("plotly_selected", source = "rcmdr-build"),
        {
          chart_build_selection(
            plotly::event_data("plotly_selected", source = "rcmdr-build")
          )
        },
        ignoreInit = TRUE
      )
    }, once = TRUE, ignoreInit = TRUE)
  }

  observeEvent(input$chart_build_subset, {
    spec <- isolate(chart_current_spec())
    result <- chart_subset_selected(state, spec, chart_build_selection())
    if (!isTRUE(result$ok)) {
      showNotification(result$error, type = "message", duration = 5)
      return()
    }
    chart_build_selection(NULL)
    refresh(gallery = TRUE)
    showNotification(sprintf(tr("Created %s from %d selected point(s)."),
                             result$name, result$rows),
                     type = "message", duration = 5)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_preview, {
    chart_preview_cache_clear()
    chart_build_selection(NULL)
    chart_revision(chart_revision() + 1L)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_apply, {
    spec <- isolate(chart_current_spec())
    if (is.null(spec)) return()
    result <- chart_apply(state, spec)
    if (!isTRUE(result$ok)) {
      showNotification(result$error %||% tr("The chart could not be applied."),
                       type = "error", duration = 8)
      return()
    }
    chart_detail_index(result$index)
    chart_build_selection(NULL)
    refresh(gallery = TRUE)
    showNotification(tr("Chart applied and added to the gallery."),
                     type = "message", duration = 4)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_advanced, {
    spec <- isolate(chart_current_spec())
    if (is.null(spec)) return()
    info <- chart_type(spec$type)
    if (is.null(info) || is.null(info$dialog)) {
      showNotification(tr("No advanced dialog is available."),
                       type = "message", duration = 4)
      return()
    }
    open_dialog_memory(state, info$dialog, info$dialog_memory(spec))
  }, ignoreInit = TRUE)

  observeEvent(input$chart_reset, {
    chart_env$pending <- NULL
    chart_build_selection(NULL)
    info <- chart_type(input$chart_type %||% "histogram")
    if (!is.null(info)) {
      slots <- chart_mapping_slots(info, "ggplot2",
                                   input$chart_type %||% "histogram")
      for (slot in names(slots)) {
        rule <- slots[[slot]]
        choices <- chart_mapping_choices(state, rule)
        selected <- if (isTRUE(rule$optional)) "" else {
          if (length(choices) > 0L) choices[[1L]] else ""
        }
        shinyWidgets::updateVirtualSelect(
          paste0("chart_map_", slot),
          selected = selected,
          session = session
        )
      }
      for (name in names(info$defaults %||% list())) {
        value <- info$defaults[[name]]
        id <- paste0("chart_opt_", name)
        if (is.logical(value)) {
          updateCheckboxInput(session, id, value = value)
        } else if (is.numeric(value)) {
          update_number_input(session, id, value)
        } else {
          updateTextInput(session, id, value = as.character(value))
        }
      }
    }
    updateSelectInput(session, "chart_palette", selected = "default")
    update_number_input(session, "chart_base_size", 12)
    updateCheckboxInput(session, "chart_grid", value = TRUE)
    updateSelectInput(session, "chart_legend", selected = "right")
    shinyWidgets::updateSpectrumInput(session, "chart_background",
                                      selected = "#ffffff")
    updateTextInput(session, "chart_title", value = "")
    updateTextInput(session, "chart_xlab", value = "")
    updateTextInput(session, "chart_ylab", value = "")
    updateTextInput(session, "chart_caption", value = "")
    updateSelectInput(session, "chart_gg_theme",
                      choices = chart_gg_theme_choices(), selected = "minimal")
    updateSelectInput(session, "chart_gg_x_format", selected = "auto")
    updateSelectInput(session, "chart_gg_y_format", selected = "auto")
    updateCheckboxInput(session, "chart_gg_polar", value = FALSE)
    updateSelectInput(session, "chart_gg_polar_theta", selected = "x")
    updateSelectInput(session, "chart_gg_position", selected = "identity")
    updateSelectInput(session, "chart_gg_smooth", selected = "lm")
    updateSelectInput(session, "chart_gg_facet_scales", selected = "fixed")
    update_number_input(session, "chart_gg_alpha", 0.7)
    updateNumericInput(session, "chart_gg_binwidth", value = 0)
    update_number_input(session, "chart_gg_jitter", 0)
    updateNumericInput(session, "chart_gg_shape", value = 19)
    updateNumericInput(session, "chart_gg_facet_ncol", value = 0)
    updateCheckboxInput(session, "chart_gg_se", value = FALSE)
    updateCheckboxInput(session, "chart_gg_flip", value = FALSE)
    updateTextInput(session, "chart_gg_subtitle", value = "")
    updateTextInput(session, "chart_gg_tag", value = "")
    updateNumericInput(session, "chart_width", value = 800)
    updateNumericInput(session, "chart_height", value = 600)
    chart_preview_cache_clear()
    chart_revision(chart_revision() + 1L)
  }, ignoreInit = TRUE)

  # -- gallery -------------------------------------------------------------

  output$chart_gallery_grid <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "gallery"))
    chart_revision()
    app_tick()
    table <- plot_list(
      state,
      query = input$chart_gallery_query %||% "",
      type = input$chart_gallery_type %||% "all",
      pinned = isTRUE(input$chart_gallery_pinned)
    )
    analysis <- input$chart_gallery_analysis %||% "all"
    if (nrow(table) > 0L && !identical(analysis, "all")) {
      keep <- vapply(table$type, function(type) {
        identical(chart_type_analysis(chart_type(type)), analysis)
      }, logical(1))
      table <- table[keep %in% TRUE, , drop = FALSE]
    }
    chart_gallery_ui_cards(table)
  })

  current_detail <- reactive({
    chart_revision()
    app_tick()
    plots <- state$plots %||% list()
    if (length(plots) == 0L) return(NULL)
    index <- chart_detail_index() %||% length(plots)
    if (index < 1L || index > length(plots)) index <- length(plots)
    list(index = index, plot = plots[[index]])
  })

  output$chart_detail <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "gallery"))
    current <- current_detail()
    if (is.null(current)) {
      return(empty_state(
        tr("No charts yet"),
        tr("Build a chart and press Apply to add it to the gallery.")
      ))
    }
    chart_detail_ui(current$plot, current$index)
  })

  output$chart_detail_plotly_ui <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "gallery"))
    if (!plotly_available()) return(NULL)
    current <- current_detail()
    if (is.null(current)) return(NULL)
    code <- plot_interactive_code(current$plot)
    if (is.null(code)) return(NULL)
    widget <- plotly_build(state, code)
    if (is.null(widget)) return(NULL)
    htmltools::tagList(
      htmltools::tags$h6(tr("Interactive preview")),
      plotly::plotlyOutput("chart_detail_plotly", height = "420px")
    )
  })

  chart_interactive_ready <- reactiveVal(FALSE)

  if (plotly_available()) {
    output$chart_detail_plotly <- plotly::renderPlotly({
      req(view_ready(input, "charts"),
          subview_ready(input, "chart_mode", "gallery"))
      chart_revision()
      current <- current_detail()
      req(current)
      code <- plot_interactive_code(current$plot)
      req(code)
      widget <- plotly_build(state, code)
      if (!is.null(widget)) chart_interactive_ready(TRUE)
      widget
    })

    # The selection observer is created only after an interactive widget has
    # been rendered: plotly warns when `event_data()` is tied to a source that
    # no widget has registered yet.
    observeEvent(chart_interactive_ready(), {
      observeEvent(
        plotly::event_data("plotly_selected", source = "rcmdr-chart"),
        {
          selected <- plotly::event_data("plotly_selected",
                                         source = "rcmdr-chart")
          chart_selection(selected)
        },
        ignoreInit = TRUE
      )
    }, once = TRUE, ignoreInit = TRUE)
  }

  observeEvent(input$chart_order, {
    request <- input$chart_order
    if (!is.list(request)) return()
    action <- request$action %||% ""
    moved <- FALSE
    if (identical(action, "up") || identical(action, "down")) {
      index <- suppressWarnings(as.integer(request$index %||% 0L))
      moved <- plot_move(state, index,
                         if (identical(action, "up")) -1L else 1L)
    } else {
      moved <- plot_reorder(state, request$from %||% NA, request$to %||% NA)
    }
    if (isTRUE(moved)) chart_revision(chart_revision() + 1L)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_action, {
    action <- input$chart_action$action %||% ""
    index <- suppressWarnings(as.integer(input$chart_action$index %||% 0L))
    if (!nzchar(action) || is.na(index) || index < 1L) return()
    plot <- plot_entry(state, index)
    if (is.null(plot)) return()

    if (identical(action, "detail")) {
      chart_detail_index(index)
    } else if (identical(action, "pin")) {
      plot_update(state, index, pinned = !isTRUE(plot$pinned))
      chart_revision(chart_revision() + 1L)
    } else if (identical(action, "rename")) {
      open_dialog_memory(state, "chartRename",
                         list(index = index, title = plot_title(plot)))
    } else if (identical(action, "delete")) {
      open_dialog_memory(state, "chartDelete", list(index = index))
    } else if (identical(action, "export")) {
      open_dialog_memory(state, "chartExport", list(index = index))
    } else if (identical(action, "reopen")) {
      spec <- plot$spec
      if (is.null(spec)) {
        showNotification(tr(
          "This plot has no saved specification. Use the advanced dialog to recreate it."
        ), type = "message", duration = 8)
        return()
      }
      chart_env$pending <- spec
      updateRadioButtons(session, "chart_mode", selected = "build")
      updateSelectInput(session, "chart_type",
                        choices = chart_type_choices_by_analysis(),
                        selected = spec$type)
      updateSelectInput(session, "chart_dataset", selected = spec$dataset)
      updateSelectInput(session, "chart_palette",
                        selected = spec$theme$palette %||% "default")
      update_number_input(session, "chart_base_size",
                          spec$theme$base_size %||% 12)
      updateCheckboxInput(session, "chart_grid",
                          value = isTRUE(spec$theme$grid %||% TRUE))
      updateSelectInput(session, "chart_legend",
                        selected = spec$theme$legend %||% "right")
      shinyWidgets::updateSpectrumInput(
        session, "chart_background",
        selected = spec$theme$background %||% "#ffffff"
      )
      title_value <- spec$labels$title %||% ""
      if (!nzchar(title_value)) {
        # A rename in the gallery is metadata; when it differs from the
        # automatic title, carry it back into the builder.
        automatic <- chart_spec_title(spec)
        if (nzchar(plot$title %||% "") && !identical(plot$title, automatic)) {
          title_value <- plot$title
        }
      }
      updateTextInput(session, "chart_title", value = title_value)
      updateTextInput(session, "chart_xlab", value = spec$labels$x %||% "")
      updateTextInput(session, "chart_ylab", value = spec$labels$y %||% "")
      updateTextInput(session, "chart_caption",
                      value = spec$labels$caption %||% "")
      updateTextInput(session, "chart_gg_subtitle",
                      value = spec$labels$subtitle %||% "")
      updateTextInput(session, "chart_gg_tag",
                      value = spec$labels$tag %||% "")
      updateSelectInput(session, "chart_gg_theme",
                        choices = chart_gg_theme_choices(),
                        selected = spec$theme$ggplot_theme %||% "minimal")
      updateSelectInput(session, "chart_gg_x_format",
                        selected = spec$options$x_format %||% "auto")
      updateSelectInput(session, "chart_gg_y_format",
                        selected = spec$options$y_format %||% "auto")
      updateCheckboxInput(session, "chart_gg_polar",
                         value = isTRUE(spec$options$polar))
      updateSelectInput(session, "chart_gg_polar_theta",
                        selected = spec$options$polar_theta %||% "x")
      updateSelectInput(session, "chart_gg_position",
                        selected = spec$options$position %||% "identity")
      updateSelectInput(session, "chart_gg_smooth",
                        selected = spec$options$smooth_method %||% "lm")
      updateSelectInput(session, "chart_gg_facet_scales",
                        selected = spec$options$facet_scales %||% "fixed")
      update_number_input(session, "chart_gg_alpha",
                          spec$options$alpha %||% 0.7)
      updateNumericInput(session, "chart_gg_binwidth",
                         value = spec$options$binwidth %||% 0)
      update_number_input(session, "chart_gg_jitter",
                          spec$options$jitter %||% 0)
      updateNumericInput(session, "chart_gg_shape",
                         value = spec$options$shape %||% 19)
      updateNumericInput(session, "chart_gg_facet_ncol",
                         value = spec$options$facet_ncol %||% 0)
      updateCheckboxInput(session, "chart_gg_se",
                          value = isTRUE(spec$options$smooth_se))
      updateCheckboxInput(session, "chart_gg_flip",
                          value = isTRUE(spec$options$flip))
      updateNumericInput(session, "chart_width",
                         value = spec$size$width %||% 800)
      updateNumericInput(session, "chart_height",
                         value = spec$size$height %||% 600)
      chart_detail_index(index)
      chart_preview_cache_clear()
      chart_revision(chart_revision() + 1L)
    } else if (identical(action, "report")) {
      showNotification(tr(
        "Every session plot is included in the report. Export the report from the Report tab."
      ), type = "message", duration = 6)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$chart_gallery_refresh, {
    chart_revision(chart_revision() + 1L)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_selection_subset, {
    current <- current_detail()
    result <- chart_subset_selected(
      state,
      if (is.null(current)) NULL else current$plot$spec,
      chart_selection()
    )
    if (!isTRUE(result$ok)) {
      showNotification(result$error, type = "message", duration = 5)
      return()
    }
    chart_selection(NULL)
    chart_revision(chart_revision() + 1L)
    refresh(gallery = TRUE)
    showNotification(sprintf(tr("Created %s from %d selected point(s)."),
                             result$name, result$rows),
                     type = "message", duration = 5)
  }, ignoreInit = TRUE)

  # -- downloads -----------------------------------------------------------

  chart_download <- function(format) {
    downloadHandler(
      filename = function() {
        request <- state$chart_export_request %||% list()
        title <- "chart"
        plot <- plot_entry(state, request$index %||% 0L)
        if (!is.null(plot)) {
          title <- gsub("[^A-Za-z0-9_-]+", "-", plot_title(plot))
        }
        paste0(title, "-", Sys.Date(), ".", format)
      },
      content = function(file) {
        request <- state$chart_export_request %||% list()
        index <- request$index %||% length(state$plots)
        plot_export(
          state, index, format = format, file = file,
          width = request$width %||% 800,
          height = request$height %||% 600,
          dpi = request$dpi %||% 96
        )
      }
    )
  }

  output$chart_download_png <- chart_download("png")
  output$chart_download_pdf <- chart_download("pdf")
  output$chart_download_svg <- chart_download("svg")
  output$chart_download_html <- chart_download("html")

  invisible(NULL)
}
