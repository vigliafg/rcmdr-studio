# Application undo/redo -------------------------------------------------------
#
# Undo is a session snapshot, not a command inversion: the stack keeps the
# active data set before and after a mutation, and the gallery metadata before
# and after a pin, rename, delete, reorder or registration.  Nothing is
# re-executed, so a command that depended on the console environment cannot
# corrupt the session when it is undone.
#
# Navigation, theme, language, dialogs and the text in Ace are intentionally
# out of scope.  The stack is bounded by count and by memory, and a project
# load clears it.

#' Empty the undo and redo stacks
#' @keywords internal
undo_clear <- function(state) {
  state$undo_stack <- list()
  state$redo_stack <- list()
  state$undo_suspended <- 0L
  state$undo_message <- NULL
  state$undo_last_label <- NULL
  invisible(TRUE)
}

#' Memory and count limits of the undo stack
#' @keywords internal
undo_limits <- function(state) {
  list(
    count = as.integer(state$options$undo_max %||% 20L),
    bytes = as.numeric(state$options$undo_max_bytes %||% (50 * 1024^2))
  )
}

undo_snapshot_bytes <- function(snapshot) {
  if (is.null(snapshot)) return(0)
  as.numeric(utils::object.size(snapshot))
}

#' Keep the newest entries within the count and memory caps
#' @keywords internal
undo_trim <- function(entries, state) {
  limits <- undo_limits(state)
  if (length(entries) > limits$count) {
    entries <- utils::tail(entries, limits$count)
  }
  if (length(entries) == 0L) return(entries)
  sizes <- vapply(entries, function(entry) entry$bytes %||% 0, numeric(1))
  total <- sum(sizes)
  while (length(entries) > 1L && total > limits$bytes) {
    total <- total - sizes[[1L]]
    entries <- entries[-1L]
    sizes <- sizes[-1L]
  }
  entries
}

#' Snapshot of one data frame
#' @keywords internal
undo_data_snapshot <- function(state, name = active_dataset(state)) {
  if (is.null(name) || !nzchar(name)) return(NULL)
  if (!exists(name, envir = state$env, inherits = FALSE)) return(NULL)
  data <- get(name, envir = state$env, inherits = FALSE)
  if (!is.data.frame(data)) return(NULL)
  list(name = name, data = data)
}

#' Snapshot of the gallery metadata
#' @keywords internal
undo_gallery_snapshot <- function(state) {
  state$plots %||% list()
}

#' Should a console command be tracked as a data mutation?
#'
#' Only commands that name the active data set in an assignment are tracked;
#' `summary(D)` and other read-only commands do not pay for a snapshot.
#' @keywords internal
undo_command_tracks_data <- function(state, code) {
  name <- active_dataset(state)
  if (is.null(name) || !nzchar(name)) return(FALSE)
  code <- paste(code, collapse = "\n")
  if (!grepl("<-", code, fixed = TRUE)) return(FALSE)
  grepl(name, code, fixed = TRUE)
}

#' Label shown in the Edit menu for a command
#' @keywords internal
undo_command_label <- function(code) {
  code <- trimws(paste(code, collapse = " "))
  code <- sub("\\s+", " ", code)
  if (!nzchar(code)) return(tr("Data change"))
  if (nchar(code) > 48L) code <- paste0(substr(code, 1L, 45L), "...")
  code
}

#' Record one reversible change
#'
#' @param kind `"data"` or `"gallery"`.
#' @param label Short human label, used by the Edit menu and the status bar.
#' @param before,after Snapshots returned by the helpers above.
#' @return `TRUE` when an entry was stored, `FALSE` for a no-op.
#' @keywords internal
undo_record <- function(state, kind, label, before, after) {
  if (isTRUE(state$undo_suspended > 0L)) return(invisible(FALSE))
  if (is.null(before) && is.null(after)) return(invisible(FALSE))
  if (identical(before, after)) return(invisible(FALSE))
  bytes <- undo_snapshot_bytes(before) + undo_snapshot_bytes(after)
  limits <- undo_limits(state)
  if (bytes > limits$bytes) {
    state$undo_skip <- list(kind = kind, label = label, bytes = bytes,
                            reason = tr("The change is larger than the undo memory cap."))
    return(invisible(FALSE))
  }
  entry <- list(
    kind = kind,
    label = label %||% tr("Change"),
    before = before,
    after = after,
    bytes = bytes,
    time = Sys.time()
  )
  state$undo_stack <- undo_trim(c(state$undo_stack %||% list(), list(entry)),
                                state)
  # A new action invalidates the redo branch.
  state$redo_stack <- list()
  state$undo_last_label <- entry$label
  state$undo_message <- NULL
  state_touch(state)
  invisible(TRUE)
}

#' Start tracking a console command
#' @keywords internal
undo_command_start <- function(state, code) {
  if (isTRUE(state$undo_suspended > 0L)) return(NULL)
  if (!undo_command_tracks_data(state, code)) return(NULL)
  undo_data_snapshot(state)
}

#' Finish tracking a console command
#' @keywords internal
undo_command_finish <- function(state, before, code) {
  if (is.null(before) || isTRUE(state$undo_suspended > 0L)) {
    return(invisible(FALSE))
  }
  after <- undo_data_snapshot(state, before$name)
  undo_record(state, "data", undo_command_label(code), before, after)
}

#' Run an expression while the automatic command tracking is suspended
#' @keywords internal
undo_suspended <- function(state, expr) {
  state$undo_suspended <- as.integer(state$undo_suspended %||% 0L) + 1L
  on.exit({
    state$undo_suspended <- max(0L, as.integer(state$undo_suspended) - 1L)
  }, add = TRUE)
  force(expr)
}

#' Status of the Edit menu entries
#' @keywords internal
undo_availability <- function(state) {
  undo <- state$undo_stack %||% list()
  redo <- state$redo_stack %||% list()
  list(
    undo = length(undo) > 0L,
    redo = length(redo) > 0L,
    undo_label = if (length(undo) > 0L) undo[[length(undo)]]$label else NULL,
    redo_label = if (length(redo) > 0L) redo[[length(redo)]]$label else NULL
  )
}

#' Restore one side of a stack
#' @keywords internal
undo_restore <- function(state, entry, side = "before") {
  if (is.null(entry)) return(invisible(FALSE))
  snapshot <- entry[[side]]
  if (is.null(snapshot)) return(invisible(FALSE))
  if (identical(entry$kind, "gallery")) {
    state$plots <- snapshot
  } else if (identical(entry$kind, "data")) {
    assign(snapshot$name, snapshot$data, envir = state$env)
    dataset_register(state, snapshot$name, refresh = TRUE)
    state$data_selection <- NULL
  } else {
    return(invisible(FALSE))
  }
  state_touch(state)
  invisible(TRUE)
}

#' Undo the last data or gallery change
#' @keywords internal
undo_apply <- function(state) {
  stack <- state$undo_stack %||% list()
  if (length(stack) == 0L) {
    state$undo_message <- tr("Nothing to undo.")
    return(invisible(FALSE))
  }
  entry <- stack[[length(stack)]]
  if (!isTRUE(undo_restore(state, entry, "before"))) {
    return(invisible(FALSE))
  }
  state$undo_stack <- stack[-length(stack)]
  state$redo_stack <- c(state$redo_stack %||% list(), list(entry))
  state$undo_message <- sprintf(tr("Undone: %s"), entry$label)
  state_touch(state)
  invisible(TRUE)
}

#' Redo the last undone change
#' @keywords internal
undo_redo <- function(state) {
  stack <- state$redo_stack %||% list()
  if (length(stack) == 0L) {
    state$undo_message <- tr("Nothing to redo.")
    return(invisible(FALSE))
  }
  entry <- stack[[length(stack)]]
  if (!isTRUE(undo_restore(state, entry, "after"))) {
    return(invisible(FALSE))
  }
  state$redo_stack <- stack[-length(stack)]
  state$undo_stack <- undo_trim(c(state$undo_stack %||% list(), list(entry)),
                                state)
  state$undo_message <- sprintf(tr("Redone: %s"), entry$label)
  state_touch(state)
  invisible(TRUE)
}

#' Edit menu labels for undo and redo
#'
#' The static menu says “Undo”; the session adds the action, so the user knows
#' what will be restored before clicking.
#' @keywords internal
undo_menu_tree <- function(tree, state) {
  availability <- undo_availability(state)
  walk <- function(nodes) {
    lapply(nodes, function(node) {
      if (identical(node$type, "menu")) {
        node$children <- walk(node$children %||% list())
      } else if (identical(node$type, "item")) {
        if (identical(node$command, "onUndo")) {
          node$label <- if (isTRUE(availability$undo)) {
            sprintf(tr("Undo: %s"), availability$undo_label)
          } else {
            tr("Undo")
          }
        } else if (identical(node$command, "onRedo")) {
          node$label <- if (isTRUE(availability$redo)) {
            sprintf(tr("Redo: %s"), availability$redo_label)
          } else {
            tr("Redo")
          }
        }
      }
      node
    })
  }
  walk(tree)
}

#' Menu status for the undo and redo commands
#' @keywords internal
undo_command_status <- function(state, command) {
  if (!command %in% c("onUndo", "onRedo")) return(NULL)
  availability <- undo_availability(state)
  if (identical(command, "onUndo")) {
    return(if (isTRUE(availability$undo)) "enabled" else "disabled")
  }
  if (identical(command, "onRedo")) {
    return(if (isTRUE(availability$redo)) "enabled" else "disabled")
  }
  NULL
}

# Data hooks -----------------------------------------------------------------

#' Track a direct data mutation around an expression
#' @keywords internal
undo_track_data <- function(state, label, expr) {
  before <- undo_data_snapshot(state)
  value <- force(expr)
  after <- undo_data_snapshot(state)
  undo_record(state, "data", label, before, after)
  invisible(value)
}

# Gallery hooks --------------------------------------------------------------

#' Track a gallery mutation around an expression
#' @keywords internal
undo_track_gallery <- function(state, label, expr) {
  before <- undo_gallery_snapshot(state)
  value <- force(expr)
  after <- undo_gallery_snapshot(state)
  undo_record(state, "gallery", label, before, after)
  invisible(value)
}
