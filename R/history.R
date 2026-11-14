# Structured command history ------------------------------------------------
#
# `state$log` is the historical contract: a character vector of commands used
# by the script, report and tests.  `state$history` is a richer, parallel list
# of records used by the Studio interface to rerun a step, reopen its dialog or
# insert the command into the script/report.  The two structures are updated by
# the same call to run_command().

#' Create a history entry
#' @keywords internal
history_entry <- function(id, time, source, command,
                          dialog_id = NULL, dialog_memory = NULL,
                          status = "ok", output = character(),
                          messages = character(), warnings = character(),
                          plot_id = NULL, duration_ms = NA_real_) {
  list(
    id = id,
    time = time,
    source = source %||% "script",
    command = command,
    dialog_id = dialog_id,
    dialog_memory = dialog_memory,
    status = status,
    output = output,
    messages = messages,
    warnings = warnings,
    plot_id = plot_id,
    duration_ms = duration_ms
  )
}

#' Next history identifier
#' @keywords internal
history_next_id <- function(state) {
  state$history_counter <- as.integer(state$history_counter %||% 0L) + 1L
  sprintf("hist-%04d", state$history_counter)
}

#' Add a history entry
#' @keywords internal
history_add <- function(state, entry) {
  if (is.null(entry)) return(invisible(NULL))
  entry$id <- entry$id %||% history_next_id(state)
  limit <- as.integer(state$options$history_length %||% 200L)
  history <- c(list(entry), state$history %||% list())
  if (length(history) > limit) history <- history[seq_len(limit)]
  state$history <- history
  if (!is.null(entry$command) && nzchar(entry$command)) {
    recent <- unique(c(entry$command, state$recent_commands %||% character()))
    state$recent_commands <- utils::head(recent, 20L)
  }
  invisible(entry)
}

#' Recent history entries
#' @param state Application state.
#' @param n Maximum number of entries.
#' @param source Optional source filter.
#' @return A list of history entries, newest first.
#' @keywords internal
history_recent <- function(state, n = 50L, source = NULL) {
  history <- state$history %||% list()
  if (!is.null(source) && nzchar(source)) {
    history <- Filter(function(entry) identical(entry$source, source), history)
  }
  utils::head(history, max(1L, as.integer(n)))
}

#' Find a history entry by id
#' @keywords internal
history_find <- function(state, id) {
  if (is.null(id) || !nzchar(id)) return(NULL)
  for (entry in state$history %||% list()) {
    if (identical(entry$id, id)) return(entry)
  }
  NULL
}

#' Clear the structured history
#' @keywords internal
history_clear <- function(state) {
  state$history <- list()
  state$history_counter <- 0L
  state$recent_commands <- character()
  state_touch(state)
  invisible(NULL)
}

#' History as a data frame
#' @keywords internal
history_as_data_frame <- function(state) {
  history <- state$history %||% list()
  if (length(history) == 0L) {
    return(data.frame(
      id = character(), time = character(), source = character(),
      command = character(), status = character(),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    id = vapply(history, function(entry) entry$id %||% NA_character_, character(1)),
    time = vapply(history, function(entry) {
      as.character(entry$time %||% NA)
    }, character(1)),
    source = vapply(history, function(entry) entry$source %||% "script", character(1)),
    command = vapply(history, function(entry) entry$command %||% "", character(1)),
    status = vapply(history, function(entry) entry$status %||% "ok", character(1)),
    stringsAsFactors = FALSE
  )
}

#' First line of a history command
#' @keywords internal
history_command_label <- function(entry, width = 120L) {
  command <- entry$command %||% ""
  line <- strsplit(command, "\n", fixed = TRUE)[[1L]]
  line <- if (length(line) == 0L) "" else line[[1L]]
  if (nchar(line) > width) paste0(substr(line, 1L, width - 1L), "\u2026") else line
}

#' Insert commands into the current script or document
#'
#' The helper keeps the existing editor buffer and appends the command without
#' executing it.  In R Markdown/knitr mode the command becomes a code chunk.
#' @keywords internal
insert_commands_into_script <- function(state, commands) {
  commands <- commands %||% character()
  commands <- commands[nzchar(commands)]
  if (length(commands) == 0L) return(invisible(FALSE))
  code <- paste(commands, collapse = "\n")
  mode <- if (is.function(document_mode)) document_mode(state) else "r"
  if (!identical(mode, "r")) {
    if (is.function(document_append_chunk)) {
      document_append_chunk(state, code, mode = mode)
      if (is.function(state$sync_document)) state$sync_document()
      return(invisible(TRUE))
    }
  }
  current <- if (is.function(state$current_document_text)) {
    state$current_document_text()
  } else {
    document_text(state)
  }
  value <- if (!nzchar(current)) code else paste(current, code, sep = "\n")
  if (is.function(state$set_script)) {
    state$set_script(value)
  } else {
    state$document$text <- value
  }
  invisible(TRUE)
}

#' Rerun a history entry
#' @keywords internal
history_rerun <- function(state, id) {
  entry <- history_find(state, id)
  if (is.null(entry)) return(invisible(NULL))
  result <- run_command(
    state, entry$command,
    source = "history",
    dialog_id = entry$dialog_id,
    dialog_memory = entry$dialog_memory
  )
  state_touch(state)
  invisible(result)
}

#' Reopen the dialog behind a history entry
#' @keywords internal
history_open_dialog <- function(state, id) {
  entry <- history_find(state, id)
  if (is.null(entry) || is.null(entry$dialog_id) || !nzchar(entry$dialog_id)) {
    if (!is.null(state$session)) {
      showNotification(tr("This history step has no dialog to reopen."),
                       type = "message", duration = 4)
    }
    return(invisible(FALSE))
  }
  spec <- get_dialog_spec(entry$dialog_id)
  if (is.null(spec) || !is.function(state$open_dialog)) {
    if (!is.null(state$session)) {
      showNotification(tr("The dialog is not available."),
                       type = "message", duration = 4)
    }
    return(invisible(FALSE))
  }
  set_dialog_memory(state, entry$dialog_id, entry$dialog_memory %||% list())
  state$open_dialog(entry$dialog_id)
  invisible(TRUE)
}

#' Insert a history command into the script
#' @keywords internal
history_insert_script <- function(state, id) {
  entry <- history_find(state, id)
  if (is.null(entry)) return(invisible(FALSE))
  insert_commands_into_script(state, entry$command)
}

#' Insert a history command as a chunk in the report document
#' @keywords internal
history_insert_report <- function(state, id) {
  entry <- history_find(state, id)
  if (is.null(entry)) return(invisible(FALSE))
  if (identical(document_mode(state), "r")) {
    if (!is.null(state$session)) {
      showNotification(
        tr("Switch to an R Markdown or knitr document to insert a chunk."),
        type = "message", duration = 5
      )
    }
    return(invisible(FALSE))
  }
  document_append_chunk(state, entry$command)
  if (is.function(state$sync_document)) state$sync_document()
  invisible(TRUE)
}
