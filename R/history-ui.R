# Structured history UI ------------------------------------------------------

history_source_labels <- function() {
  stats::setNames(
    c("all", "dialog", "script", "console", "menu", "data", "chart",
      "report", "environment", "model", "history", "checkpoint"),
    c(tr("All sources"), tr("Dialogs"), tr("Script"), tr("Console"),
      tr("Menus"), tr("Data Studio"), tr("Chart Studio"), tr("Report"),
      tr("Environment"), tr("Models"), tr("History"), tr("Checkpoints"))
  )
}

history_status_label <- function(status) {
  switch(
    status,
    ok = tr("OK"),
    error = tr("Error"),
    empty = tr("Empty"),
    status %||% tr("OK")
  )
}

history_status_labels <- function() {
  stats::setNames(
    c("all", "ok", "error", "empty"),
    c(tr("All statuses"), tr("OK"), tr("Errors"), tr("Empty"))
  )
}

history_status_class <- function(status) {
  switch(
    status,
    ok = "ok",
    error = "error",
    empty = "muted",
    "muted"
  )
}

history_card_ui <- function(entry, pinned = FALSE) {
  output <- paste(entry$output %||% character(), collapse = "\n")
  messages <- paste(entry$messages %||% character(), collapse = "\n")
  duration <- entry$duration_ms
  duration_label <- if (is.null(duration) || is.na(duration)) {
    ""
  } else if (duration < 1000) {
    sprintf("%.0f ms", duration)
  } else {
    sprintf("%.1f s", duration / 1000)
  }
  htmltools::tags$div(
    class = paste0("rcmdr-history-card", if (isTRUE(pinned)) " pinned" else ""),
    `data-history-id` = entry$id,
    htmltools::tags$div(
      class = "rcmdr-history-head",
      status_pill(history_status_label(entry$status),
                  history_status_class(entry$status)),
      htmltools::tags$span(class = "rcmdr-history-source",
                           entry$source %||% "script"),
      htmltools::tags$span(class = "rcmdr-history-time",
                           format(entry$time %||% Sys.time(), "%H:%M:%S")),
      if (nzchar(duration_label)) {
        htmltools::tags$span(class = "rcmdr-history-time", duration_label)
      },
      htmltools::tags$div(
        class = "ms-auto d-flex gap-1",
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          `data-history-action` = if (isTRUE(pinned)) "unpin" else "pin",
          `data-history-id` = entry$id,
          onclick = sprintf(
            "rcmdrHistoryClick(this, '%s'); return false;",
            if (isTRUE(pinned)) "unpin" else "pin"
          ),
          if (isTRUE(pinned)) tr("Unpin") else tr("Pin")
        ),
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          `data-history-action` = "rerun", `data-history-id` = entry$id,
          onclick = "rcmdrHistoryClick(this, 'rerun'); return false;",
          tr("Rerun")
        ),
        if (!is.null(entry$dialog_id) && nzchar(entry$dialog_id)) {
          htmltools::tags$button(
            type = "button", class = "btn btn-sm btn-outline-secondary",
            `data-history-action` = "dialog", `data-history-id` = entry$id,
            onclick = "rcmdrHistoryClick(this, 'dialog'); return false;",
            tr("Open dialog")
          )
        },
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          `data-history-action` = "script", `data-history-id` = entry$id,
          onclick = "rcmdrHistoryClick(this, 'script'); return false;",
          tr("To script")
        ),
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          `data-history-action` = "report", `data-history-id` = entry$id,
          onclick = "rcmdrHistoryClick(this, 'report'); return false;",
          tr("To report")
        ),
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          `data-history-action` = "copy", `data-history-id` = entry$id,
          `data-history-command` = entry$command %||% "",
          onclick = "rcmdrHistoryClick(this, 'copy'); return false;",
          tr("Copy")
        )
      )
    ),
    htmltools::tags$pre(class = "rcmdr-history-command", entry$command %||% ""),
    if (nzchar(output)) {
      htmltools::tags$details(
        class = "rcmdr-history-output",
        htmltools::tags$summary(sprintf(tr("Output (%d lines)"),
                                        length(entry$output %||% character()))),
        htmltools::tags$pre(paste(entry$output, collapse = "\n"))
      )
    },
    if (nzchar(messages)) {
      htmltools::tags$details(
        class = "rcmdr-history-messages",
        htmltools::tags$summary(tr("Messages")),
        htmltools::tags$pre(messages)
      )
    }
  )
}

history_cards_ui <- function(entries, pinned = character()) {
  if (length(entries) == 0L) {
    return(empty_state(
      tr("No commands yet"),
      tr("Run a dialog or a script command and it will appear here.")
    ))
  }
  htmltools::tagList(lapply(entries, function(entry) {
    history_card_ui(entry, pinned = entry$id %in% pinned)
  }))
}

history_pane_ui <- function() {
  htmltools::tagList(
    studio_toolbar(
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        textInput("history_filter", NULL,
                  placeholder = tr("Filter commands..."), width = "240px")
      ),
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        selectInput("history_source", NULL, choices = history_source_labels(),
                    width = "160px")
      ),
      actionButton("history_clear", tr("Clear history"),
                   class = "btn-sm btn-outline-secondary")
    ),
    uiOutput("history_cards")
  )
}

#' Filter history entries for the UI
#' @keywords internal
history_filter_entries <- function(entries, query = "", source = "all",
                                   status = "all") {
  if (!is.null(source) && nzchar(source) && !identical(source, "all")) {
    entries <- Filter(function(entry) identical(entry$source, source), entries)
  }
  if (!is.null(status) && nzchar(status) && !identical(status, "all")) {
    entries <- Filter(function(entry) {
      identical(entry$status %||% "ok", status)
    }, entries)
  }
  query <- tolower(trimws(query %||% ""))
  if (!nzchar(query)) return(entries)
  Filter(function(entry) {
    haystack <- paste(entry$command %||% "", entry$source %||% "",
                      paste(entry$output %||% character(), collapse = " "),
                      paste(entry$messages %||% character(), collapse = " "))
    grepl(query, tolower(haystack), fixed = TRUE)
  }, entries)
}

# Output and Messages workspaces --------------------------------------------

#' Toolbar and cards for the Studio Output tab
#' @keywords internal
output_studio_ui <- function() {
  htmltools::tagList(
    studio_toolbar(
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        textInput("output_filter", NULL, placeholder = tr("Search output..."),
                  width = "230px")
      ),
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        selectInput("output_status", NULL, choices = history_status_labels(),
                    width = "150px")
      ),
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        selectInput("output_source", NULL, choices = history_source_labels(),
                    width = "160px")
      ),
      checkboxInput("output_pinned", tr("Pinned only"), value = FALSE),
      actionButton("output_clear", tr("Clear raw output"),
                   class = "btn-sm btn-outline-secondary")
    ),
    uiOutput("output_cards"),
    htmltools::tags$details(
      class = "rcmdr-output-raw", open = "open",
      htmltools::tags$summary(tr("Raw output")),
      verbatimTextOutput("output_text")
    )
  )
}

#' Messages grouped by severity
#' @keywords internal
messages_severity_labels <- function() {
  stats::setNames(
    c("all", "error", "warning", "message"),
    c(tr("All severities"), tr("Errors"), tr("Warnings"), tr("Messages"))
  )
}

#' Toolbar and list for the Studio Messages tab
#' @keywords internal
messages_studio_ui <- function() {
  htmltools::tagList(
    studio_toolbar(
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        textInput("messages_filter", NULL,
                  placeholder = tr("Search messages..."), width = "230px")
      ),
      htmltools::tags$div(
        class = "rcmdr-toolbar-field",
        selectInput("messages_severity", NULL,
                    choices = messages_severity_labels(), width = "170px")
      ),
      actionButton("messages_clear", tr("Clear"),
                   class = "btn-sm btn-outline-secondary")
    ),
    uiOutput("messages_cards"),
    htmltools::tags$details(
      class = "rcmdr-output-raw", open = "open",
      htmltools::tags$summary(tr("Raw messages")),
      verbatimTextOutput("messages_text")
    )
  )
}
