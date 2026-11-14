# Session checkpoints --------------------------------------------------------
#
# Data checkpoints (Wave 1) snapshot a data frame before a structural change.
# Session checkpoints are lighter: they record which objects were active and
# which documents were open.  They never copy the data set, so they are cheap
# and do not duplicate the data-checkpoint cap.

#' Create a session checkpoint
#'
#' @param state Application state.
#' @param label Optional label.
#' @return The checkpoint, invisibly.
#' @keywords internal
session_checkpoint_create <- function(state, label = "") {
  state$session_checkpoint_counter <-
    as.integer(state$session_checkpoint_counter %||% 0L) + 1L
  entry <- list(
    id = sprintf("sckpt-%04d", state$session_checkpoint_counter),
    time = Sys.time(),
    label = if (nzchar(trimws(label %||% ""))) {
      trimws(label)
    } else {
      tr("Session checkpoint")
    },
    dataset = state$active_dataset,
    model = state$active_model,
    documents = document_list(state),
    active_document = state$active_document,
    objects = ls(envir = state$env),
    project_path = state$project_path
  )
  checkpoints <- c(list(entry), state$session_checkpoints %||% list())
  limit <- as.integer(state$options$session_checkpoint_max %||% 10L)
  state$session_checkpoints <- utils::head(checkpoints, limit)
  state_touch(state)
  invisible(entry)
}

#' List session checkpoints
#' @keywords internal
session_checkpoint_list <- function(state) {
  checkpoints <- state$session_checkpoints %||% list()
  if (length(checkpoints) == 0L) {
    return(data.frame(
      id = character(), time = character(), label = character(),
      dataset = character(), model = character(), documents = integer(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(checkpoints, function(entry) {
    data.frame(
      id = entry$id,
      time = format(entry$time %||% Sys.time(), "%Y-%m-%d %H:%M:%S"),
      label = entry$label %||% "",
      dataset = entry$dataset %||% "",
      model = entry$model %||% "",
      documents = nrow(entry$documents %||% data.frame()),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Get one session checkpoint
#' @keywords internal
session_checkpoint_get <- function(state, id) {
  for (entry in state$session_checkpoints %||% list()) {
    if (identical(entry$id, id)) return(entry)
  }
  NULL
}

#' Restore a session checkpoint
#'
#' Objects and data sets that no longer exist are skipped; the checkpoint never
#' re-runs a command and never recreates a model.
#' @keywords internal
session_checkpoint_restore <- function(state, id) {
  entry <- session_checkpoint_get(state, id)
  if (is.null(entry)) return(FALSE)

  if (!is.null(entry$dataset) &&
      exists(entry$dataset, envir = state$env, inherits = FALSE)) {
    state$active_dataset <- entry$dataset
  }
  if (!is.null(entry$model) &&
      exists(entry$model, envir = state$env, inherits = FALSE)) {
    state$active_model <- entry$model
  }

  restored_document <- NULL
  for (i in seq_len(nrow(entry$documents %||% data.frame()))) {
    row <- entry$documents[i, , drop = FALSE]
    document_id <- row$id[[1L]]
    if (document_id %in% names(state$documents %||% list())) {
      restored_document <- document_id
      break
    }
    path <- row$path[[1L]]
    if (!is.na(path) && nzchar(path) && file.exists(path)) {
      text <- tryCatch(
        paste(readLines(path, warn = FALSE, encoding = "UTF-8"),
              collapse = "\n"),
        error = function(e) NULL
      )
      if (!is.null(text)) {
        restored_document <- document_create(
          state,
          mode = row$mode[[1L]] %||% "r",
          title = row$title[[1L]] %||% basename(path),
          text = text,
          path = path,
          activate = FALSE
        )
        break
      }
    }
  }
  if (!is.null(restored_document)) document_activate(state, restored_document)

  state_touch(state)
  TRUE
}

#' Delete a session checkpoint
#' @keywords internal
session_checkpoint_delete <- function(state, id) {
  before <- length(state$session_checkpoints %||% list())
  state$session_checkpoints <- Filter(
    function(entry) !identical(entry$id, id),
    state$session_checkpoints %||% list()
  )
  if (length(state$session_checkpoints) == before) return(FALSE)
  state_touch(state)
  TRUE
}
