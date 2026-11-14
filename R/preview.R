# Isolated preview engine ----------------------------------------------------
#
# Previews are evaluated in a child of the session environment.  They never
# call run_command(), never append to the command log and never touch
# state$output or state$plots.  The caller is responsible for cleaning up the
# temporary files, or can call preview_cleanup().

.preview_state <- new.env(parent = emptyenv())
.preview_state$files <- character()

preview_track <- function(path) {
  .preview_state$files <- unique(c(.preview_state$files, path))
  invisible(path)
}

#' Remove all preview files created in this session
#' @keywords internal
preview_cleanup <- function() {
  files <- .preview_state$files
  .preview_state$files <- character()
  if (length(files) > 0L) {
    unlink(files[file.exists(files)], force = TRUE)
  }
  invisible(length(files))
}

#' Isolated evaluation environment for previews
#' @keywords internal
preview_env <- function(state) {
  new.env(parent = state$env)
}

#' Shallow copy of the application state for dialog dry-runs
#'
#' The copy keeps `state$env` so the dialog can inspect the active data set, but
#' removes the callbacks that touch the live Shiny session or the real state.
#' @keywords internal
preview_state_clone <- function(state) {
  bindings <- ls(state, all.names = TRUE)
  values <- mget(bindings, envir = state, inherits = FALSE)
  copy <- list2env(values, parent = emptyenv())
  copy$notify <- function() invisible(NULL)
  copy$session <- NULL
  copy$open_dialog <- NULL
  copy$set_script <- NULL
  copy$sync_document <- NULL
  copy$show_tab <- NULL
  copy$help_show <- NULL
  copy$current_dialog <- state$current_dialog
  copy
}

#' Render a base R plot preview
#'
#' @param state Application state.
#' @param code Character expression to evaluate.
#' @param width,height Image size in pixels.
#' @return A list with `type`, `file`, `output` and `error`.
#' @keywords internal
preview_plot <- function(state, code, width = 800, height = 600) {
  code <- paste(code, collapse = "\n")
  if (!nzchar(trimws(code))) {
    return(list(type = "none", file = NULL, output = character(),
                error = tr("No code to preview.")))
  }
  file <- tempfile("rcmdr-preview-", fileext = ".png")
  preview_track(file)
  error <- NULL
  output <- character()

  grDevices::png(filename = file, width = width, height = height, res = 96)
  device <- grDevices::dev.cur()
  on.exit({
    if (device %in% grDevices::dev.list()) {
      try(grDevices::dev.off(device), silent = TRUE)
    }
  }, add = TRUE)

  output <- tryCatch(
    utils::capture.output(
      eval(parse(text = code), envir = preview_env(state))
    ),
    error = function(e) {
      error <<- conditionMessage(e)
      character()
    }
  )

  if (device %in% grDevices::dev.list()) grDevices::dev.off(device)
  list(type = "image", file = file, output = output, error = error)
}

#' Evaluate a plotly preview
#' @keywords internal
preview_plotly <- function(state, code) {
  if (!plotly_available() || is.null(code) || !nzchar(code)) {
    return(list(type = "none", widget = NULL, error = NULL))
  }
  widget <- tryCatch(
    eval(parse(text = code), envir = preview_env(state)),
    error = function(e) NULL
  )
  list(type = if (is.null(widget)) "none" else "plotly",
       widget = widget, error = NULL)
}

#' Render Markdown preview HTML
#' @keywords internal
preview_markdown <- function(text) {
  text <- paste(text, collapse = "\n")
  if (!nzchar(text)) return("")
  if (requireNamespace("commonmark", quietly = TRUE)) {
    return(as.character(commonmark::markdown_html(text)))
  }
  paste0("<pre class=\"rcmdr-help-text\">",
         htmltools::htmlEscape(text), "</pre>")
}

#' Evaluate a command preview without logging it
#' @keywords internal
preview_output <- function(state, code) {
  code <- paste(code, collapse = "\n")
  if (!nzchar(trimws(code))) return(list(output = character(), error = NULL))
  error <- NULL
  output <- tryCatch(
    utils::capture.output(
      eval(parse(text = code), envir = preview_env(state))
    ),
    error = function(e) {
      error <<- conditionMessage(e)
      character()
    }
  )
  list(output = output, error = error)
}
