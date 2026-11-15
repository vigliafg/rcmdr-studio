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
                          error = NULL, plot_id = NULL,
                          duration_ms = NA_real_) {
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
    error = error,
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

# Structured messages -------------------------------------------------------

#' Record a structured message
#'
#' `state$messages` remains the plain text buffer; this list preserves the
#' severity, the command and the history entry so the Messages tab can filter
#' and navigate.
#' @keywords internal
message_add <- function(state, severity, text, command = NULL) {
  text <- paste(text, collapse = "\n")
  if (!nzchar(text)) return(invisible(NULL))
  state$message_counter <- as.integer(state$message_counter %||% 0L) + 1L
  entry <- list(
    id = sprintf("msg-%04d", state$message_counter),
    severity = severity %||% "message",
    text = text,
    command = command %||% "",
    history_id = state$execution_id %||% NULL,
    time = Sys.time()
  )
  state$message_entries <- c(list(entry), state$message_entries %||% list())
  limit <- as.integer(state$options$history_length %||% 200L) * 5L
  state$message_entries <- utils::head(state$message_entries, limit)
  invisible(entry)
}

#' Structured messages as a data frame
#' @keywords internal
messages_as_data_frame <- function(state) {
  entries <- state$message_entries %||% list()
  if (length(entries) == 0L) {
    return(data.frame(
      id = character(), severity = character(), text = character(),
      command = character(), time = character(), stringsAsFactors = FALSE
    ))
  }
  data.frame(
    id = vapply(entries, function(entry) entry$id %||% "", character(1)),
    severity = vapply(entries, function(entry) entry$severity %||% "message",
                      character(1)),
    text = vapply(entries, function(entry) entry$text %||% "", character(1)),
    command = vapply(entries, function(entry) entry$command %||% "",
                     character(1)),
    time = vapply(entries, function(entry) {
      format(entry$time %||% Sys.time(), "%H:%M:%S")
    }, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Filter structured messages
#' @keywords internal
messages_filter <- function(entries, query = "", severity = "all") {
  if (!is.null(severity) && nzchar(severity) && !identical(severity, "all")) {
    entries <- Filter(function(entry) {
      identical(entry$severity %||% "message", severity)
    }, entries)
  }
  query <- tolower(trimws(query %||% ""))
  if (!nzchar(query)) return(entries)
  Filter(function(entry) {
    haystack <- paste(entry$text %||% "", entry$command %||% "")
    grepl(query, tolower(haystack), fixed = TRUE)
  }, entries)
}

#' Clear structured messages
#' @keywords internal
messages_clear <- function(state) {
  state$message_entries <- list()
  state$message_counter <- 0L
  invisible(NULL)
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

#' Pin or unpin a history entry
#' @keywords internal
history_toggle_pin <- function(state, id) {
  if (is.null(id) || !nzchar(id)) return(invisible(FALSE))
  pinned <- state$history_pinned %||% character()
  if (id %in% pinned) {
    state$history_pinned <- setdiff(pinned, id)
    value <- FALSE
  } else {
    state$history_pinned <- unique(c(id, pinned))
    value <- TRUE
  }
  state_touch(state)
  invisible(value)
}

#' Pinned history identifiers
#' @keywords internal
history_pinned_ids <- function(state) state$history_pinned %||% character()

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
  state$history_pinned <- character()
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
  availability <- command_availability(state, entry$dialog_id)
  if (!identical(availability$status, "enabled")) {
    if (!is.null(state$session)) {
      showNotification(command_status_message(availability$status),
                       type = "warning", duration = 5)
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
