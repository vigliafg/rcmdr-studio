# Console Studio -------------------------------------------------------------
#
# The Console is the direct entry point to the same command engine used by the
# dialogs and the script.  Every command goes through run_command(), so the
# command log, the structured history, the captured output and the plot
# gallery stay in sync.
#
# R is single threaded: interactive prompts cannot be answered from a browser.
# `console_is_interactive()` detects them and the console refuses to run them
# instead of blocking the session.

# History --------------------------------------------------------------------

#' Record a console command
#' @keywords internal
console_history_add <- function(state, code) {
  code <- paste(code, collapse = "\n")
  if (!nzchar(trimws(code))) return(invisible(NULL))
  limit <- as.integer(state$options$console_history_length %||% 100L)
  history <- c(state$console_history %||% character(), code)
  state$console_history <- utils::tail(history, max(1L, limit))
  state$console_index <- length(state$console_history) + 1L
  invisible(state$console_history)
}

#' Recall a console command
#'
#' `direction = -1` walks backwards (older), `direction = 1` walks forwards.
#' The index is kept in the state; an empty string means "past the newest".
#' @keywords internal
console_history_recall <- function(state, direction = -1L) {
  history <- state$console_history %||% character()
  if (length(history) == 0L) return("")
  index <- state$console_index %||% (length(history) + 1L)
  index <- index + as.integer(direction)
  index <- max(1L, min(length(history) + 1L, index))
  state$console_index <- index
  if (index > length(history)) "" else history[[index]]
}

#' Console history entries, newest first
#' @keywords internal
console_entries <- function(state, query = "", status = "all", limit = 12L) {
  entries <- history_recent(state, limit, source = "console")
  query <- tolower(trimws(query %||% ""))
  if (nzchar(query)) {
    entries <- Filter(function(entry) {
      haystack <- paste(entry$command %||% "",
                        paste(entry$output %||% character(), collapse = " "),
                        paste(entry$messages %||% character(), collapse = " "))
      grepl(query, tolower(haystack), fixed = TRUE)
    }, entries)
  }
  if (!is.null(status) && nzchar(status) && !identical(status, "all")) {
    entries <- Filter(function(entry) {
      identical(entry$status %||% "ok", status)
    }, entries)
  }
  entries
}

#' Run a console command
#'
#' Returns the `run_command()` result, or a list with `status = "blocked"` when
#' the command needs an interactive prompt.
#' @keywords internal
console_execute <- function(state, code) {
  code <- paste(code, collapse = "\n")
  if (!nzchar(trimws(code))) {
    return(list(status = "empty", code = code))
  }
  if (console_is_interactive(code)) {
    return(list(
      status = "blocked", code = code,
      error = tr("Interactive commands cannot run in the browser console.")
    ))
  }
  started <- Sys.time()
  result <- tryCatch(
    run_command(state, code, source = "console"),
    error = function(e) {
      list(status = "error", error = conditionMessage(e),
           output = character(), messages = character(),
           warnings = character())
    }
  )
  console_history_add(state, code)
  state$console_last <- list(
    code = code,
    status = result$status %||% "ok",
    time = started,
    duration_ms = as.numeric(difftime(Sys.time(), started, units = "secs")) * 1000
  )
  result
}

console_status_labels <- function() {
  stats::setNames(
    c("all", "ok", "error", "empty"),
    c(tr("All statuses"), tr("OK"), tr("Errors"), tr("Empty"))
  )
}

#' Console toolbar, log and input
#' @keywords internal
console_studio_ui <- function() {
  htmltools::tagList(
    htmltools::div(
      class = "rcmdr-console",
      htmltools::div(
        class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
        textInput("console_filter", NULL, placeholder = tr("Search console..."),
                  width = "220px"),
        selectInput("console_status", NULL, choices = console_status_labels(),
                    width = "150px"),
        actionButton("console_clear", tr("Clear"),
                     class = "btn-sm btn-outline-secondary"),
        uiOutput("console_count_ui", inline = TRUE)
      ),
      uiOutput("console_status_ui"),
      htmltools::div(class = "rcmdr-console-log", uiOutput("console_log")),
      htmltools::div(
        class = "rcmdr-console-input",
        htmltools::tags$div(
          class = "d-flex gap-1 align-items-end",
          textAreaInput(
            "console_input", NULL, width = "100%", rows = 2, resize = "vertical",
            placeholder = tr("Type an R command and press Enter")
          ),
          actionButton("console_prev", "\u2191", title = tr("Previous command"),
                       class = "btn-sm btn-outline-secondary"),
          actionButton("console_next", "\u2193", title = tr("Next command"),
                       class = "btn-sm btn-outline-secondary"),
          actionButton("console_run", tr("Run"), class = "btn-primary")
        )
      ),
      htmltools::tags$p(
        class = "rcmdr-console-note",
        tr("Commands are logged and added to the history. Interactive prompts cannot be answered from the browser.")
      )
    )
  )
}
