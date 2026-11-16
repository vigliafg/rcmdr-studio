# Chart composition ---------------------------------------------------------
#
# A composition is a chart specification whose children are other chart
# specifications taken from the gallery.  patchwork assembles them; the
# generated command is a single expression so that the isolated preview, the
# apply action and the export all work unchanged.

#' Layout presets for chart compositions
#' @keywords internal
chart_compose_layouts <- function() {
  stats::setNames(
    c("1x2", "2x1", "2x2", "1+2", "wrap"),
    c(
      tr("Side by side"),
      tr("Stacked"),
      tr("Grid 2 x 2"),
      tr("Top, then two below"),
      tr("Automatic wrap")
    )
  )
}

#' Default options of a composition
#' @keywords internal
chart_compose_defaults <- function() {
  list(
    layout = "1x2",
    guides = "collect",
    tag_levels = "A",
    ncol = 0L
  )
}

#' Composition chart type
#' @keywords internal
chart_compose_types <- function() {
  list(
    compose = list(
      label = tr("Chart composition"),
      icon = "grid",
      group = "composition",
      analysis = "composite",
      description = tr(
        "Combine two or more charts from the gallery with patchwork."
      ),
      requires = "patchwork",
      mapping = list(),
      defaults = chart_compose_defaults(),
      controls = function(spec) {
        options <- utils::modifyList(chart_compose_defaults(),
                                     spec$options %||% list())
        htmltools::tagList(
          selectInput(
            "chart_opt_layout", tr("Layout"),
            choices = chart_compose_layouts(),
            selected = options$layout %||% "1x2", width = "100%"
          ),
          selectInput(
            "chart_opt_guides", tr("Legends"),
            choices = stats::setNames(
              c("collect", "keep"),
              c(tr("Collect into one legend"), tr("Keep separate"))
            ),
            selected = options$guides %||% "collect", width = "100%"
          ),
          selectInput(
            "chart_opt_tag_levels", tr("Panel tags"),
            choices = stats::setNames(
              c("A", "a", "1", ""),
              c("A, B, C", "a, b, c", "1, 2, 3", tr("None"))
            ),
            selected = options$tag_levels %||% "A", width = "100%"
          ),
          help_text(tr(
            "Pick the charts to combine in the panel below; each one keeps its own command."
          ))
        )
      }
    )
  )
}

#' Child specifications of a composition
#' @keywords internal
chart_compose_children <- function(spec) {
  children <- (spec$options %||% list())$children %||% list()
  if (length(children) == 0L) return(list())
  keep <- vapply(children, function(child) {
    is.list(child) && !identical(child$type %||% "", "compose")
  }, logical(1))
  children[keep]
}

chart_compose_wrap <- function(expression) {
  paste0("(", expression, ")")
}

#' Join child expressions according to the layout preset
#' @keywords internal
chart_compose_join <- function(expressions, layout = "1x2") {
  expressions <- vapply(expressions, chart_compose_wrap, character(1))
  n <- length(expressions)
  if (n == 0L) return("")
  if (n == 1L) return(expressions[[1L]])
  if (identical(layout, "2x1")) return(paste(expressions, collapse = " / "))
  if (identical(layout, "1+2") && n >= 2L) {
    first <- expressions[[1L]]
    rest <- expressions[-1L]
    if (length(rest) == 1L) return(paste(first, rest[[1L]], sep = " / "))
    return(sprintf("%s / (%s)", first, paste(rest, collapse = " | ")))
  }
  if (identical(layout, "2x2") && n >= 2L) {
    rows <- split(expressions, ceiling(seq_along(expressions) / 2))
    rows <- vapply(rows, function(row) {
      if (length(row) == 1L) return(row[[1L]])
      sprintf("(%s)", paste(row, collapse = " | "))
    }, character(1))
    return(paste(rows, collapse = " / "))
  }
  if (identical(layout, "wrap")) {
    return(sprintf("patchwork::wrap_plots(%s)", paste(expressions,
                                                      collapse = ", ")))
  }
  paste(expressions, collapse = " | ")
}

#' patchwork composition expression of a specification
#' @keywords internal
chart_compose_object <- function(spec) {
  children <- chart_compose_children(spec)
  if (length(children) < 2L) {
    stop("A composition needs at least two charts from the gallery.",
         call. = FALSE)
  }
  expressions <- vapply(children, function(child) {
    chart_ggplot_object(child)
  }, character(1))
  options <- utils::modifyList(chart_compose_defaults(),
                               spec$options %||% list())
  composed <- chart_compose_join(expressions,
                                 options$layout %||% "1x2")

  layout_args <- character()
  if (identical(options$guides %||% "collect", "collect")) {
    layout_args <- c(layout_args, "guides = 'collect'")
  }
  ncol <- suppressWarnings(as.integer(options$ncol %||% 0L))
  if (!is.na(ncol) && ncol > 0L && identical(options$layout, "wrap")) {
    layout_args <- c(layout_args, sprintf("ncol = %d", ncol))
  }
  if (length(layout_args) > 0L) {
    composed <- paste0(composed, " + patchwork::plot_layout(",
                       paste(layout_args, collapse = ", "), ")")
  }

  annotation_args <- character()
  tags <- options$tag_levels %||% ""
  if (nzchar(tags)) {
    annotation_args <- c(annotation_args, sprintf("tag_levels = '%s'", tags))
  }
  labels <- spec$labels %||% list()
  add_label <- function(name, value) {
    value <- as.character(value %||% "")[1L]
    if (!is.na(value) && nzchar(value)) {
      annotation_args <<- c(annotation_args,
                            sprintf("%s = %s", name, chart_quote(value)))
    }
  }
  add_label("title", labels$title)
  add_label("caption", labels$caption)
  if (length(annotation_args) > 0L) {
    composed <- paste0(composed, " + patchwork::plot_annotation(",
                       paste(annotation_args, collapse = ", "), ")")
  }
  composed
}

#' Complete composition command
#' @keywords internal
chart_compose_command <- function(spec) {
  sprintf("print(%s)", chart_compose_object(spec))
}

#' Title of a composition
#' @keywords internal
chart_compose_title <- function(spec) {
  children <- chart_compose_children(spec)
  sprintf(tr("Composition of %d charts"), length(children))
}
