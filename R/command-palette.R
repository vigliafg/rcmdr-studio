# Command palette ------------------------------------------------------------
#
# The palette is a searchable index over the menu tree, the help catalogue,
# datasets, variables and the structured history.  It always runs the existing
# commands: it is a navigation layer, not a second command engine.

palette_type_priority <- function() {
  c(menu = 1L, help = 2L, dataset = 3L, variable = 4L, history = 5L)
}

#' Build the palette index
#' @keywords internal
palette_index <- function(state) {
  rows <- list()

  leaves <- menu_leaves(menu_tree())
  if (nrow(leaves) > 0L) {
    for (i in seq_len(nrow(leaves))) {
      row <- leaves[i, , drop = FALSE]
      status <- command_status(state, row$command, row$activation, row$install)
      if (identical(status, "hidden")) next
      rows[[length(rows) + 1L]] <- data.frame(
        id = row$command,
        type = "menu",
        label = row$label,
        path = row$path,
        keywords = paste(row$label, row$path, row$command),
        enabled = identical(status, "enabled"),
        reason = switch(
          status,
          enabled = "",
          porting = tr("Not ported yet"),
          inactive = tr("Not available for the current data set"),
          ""
        ),
        stringsAsFactors = FALSE
      )
    }
  }

  topics <- tryCatch(help_catalog(), error = function(e) NULL)
  if (!is.null(topics) && nrow(topics) > 0L) {
    for (i in seq_len(nrow(topics))) {
      topic <- topics[i, , drop = FALSE]
      rows[[length(rows) + 1L]] <- data.frame(
        id = topic$id,
        type = "help",
        label = topic$title,
        path = topic$category %||% "help",
        keywords = paste(topic$title, topic$category, topic$id),
        enabled = TRUE,
        reason = "",
        stringsAsFactors = FALSE
      )
    }
  }

  objects <- ls(envir = state$env)
  if (length(objects) > 0L) {
    datasets <- objects[vapply(objects, function(name) {
      is.data.frame(get(name, envir = state$env, inherits = FALSE))
    }, logical(1))]
    for (name in datasets) {
      rows[[length(rows) + 1L]] <- data.frame(
        id = name,
        type = "dataset",
        label = name,
        path = tr("Data"),
        keywords = paste(name, "dataset data frame"),
        enabled = TRUE,
        reason = "",
        stringsAsFactors = FALSE
      )
    }
  }

  vars <- variables(state)
  if (length(vars) > 0L) {
    dataset <- active_dataset(state) %||% ""
    for (name in vars) {
      rows[[length(rows) + 1L]] <- data.frame(
        id = name,
        type = "variable",
        label = name,
        path = dataset,
        keywords = paste(name, dataset, "variable"),
        enabled = TRUE,
        reason = "",
        stringsAsFactors = FALSE
      )
    }
  }

  history <- history_recent(state, 50L)
  if (length(history) > 0L) {
    for (entry in history) {
      rows[[length(rows) + 1L]] <- data.frame(
        id = entry$id,
        type = "history",
        label = history_command_label(entry),
        path = entry$source %||% "script",
        keywords = paste(entry$command %||% "", entry$source %||% ""),
        enabled = TRUE,
        reason = "",
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(rows) == 0L) {
    return(data.frame(
      id = character(), type = character(), label = character(),
      path = character(), keywords = character(), enabled = logical(),
      reason = character(), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

#' Score a fuzzy match
#' @keywords internal
palette_score <- function(query, text) {
  query <- tolower(trimws(query %||% ""))
  text <- tolower(text %||% "")
  if (!nzchar(query)) return(0)
  if (!nzchar(text)) return(0)
  if (identical(text, query)) return(1000)
  if (startsWith(text, query)) return(900 - nchar(text))
  position <- regexpr(query, text, fixed = TRUE)[[1L]]
  if (position > 0L) return(700 - position - nchar(text) / 10)
  # Subsequence match: every query character appears in order.
  chars <- strsplit(query, "", fixed = TRUE)[[1L]]
  pos <- 1L
  score <- 0
  for (ch in chars) {
    found <- regexpr(ch, substring(text, pos), fixed = TRUE)[[1L]]
    if (found < 0L) return(0)
    score <- score + 1
    pos <- pos + found
  }
  if (score == length(chars)) 300 - pos else 0
}

#' Search the palette index
#' @keywords internal
palette_search <- function(query, index, limit = 20L) {
  if (is.null(index) || nrow(index) == 0L) return(index)
  query <- trimws(query %||% "")

  if (!nzchar(query)) {
    priorities <- palette_type_priority()
    index$priority <- unname(priorities[index$type] %||% 99L)
    index <- index[order(!index$enabled, index$priority, index$label), , drop = FALSE]
    index$priority <- NULL
    return(utils::head(index, max(1L, as.integer(limit))))
  }

  scores <- vapply(seq_len(nrow(index)), function(i) {
    row <- index[i, , drop = FALSE]
    max(
      palette_score(query, row$label),
      palette_score(query, row$path),
      palette_score(query, row$keywords)
    )
  }, numeric(1))
  index$score <- scores
  index <- index[index$score > 0, , drop = FALSE]
  if (nrow(index) == 0L) {
    index$score <- NULL
    return(index)
  }
  # When a contiguous match exists, subsequence-only matches are usually noise
  # (for example "logist" matching "Plot geometric distribution").
  if (any(index$score >= 500)) {
    index <- index[index$score >= 500, , drop = FALSE]
  }
  priorities <- palette_type_priority()
  index$priority <- unname(priorities[index$type] %||% 99L)
  index <- index[order(-index$score, !index$enabled, index$priority,
                       index$label), , drop = FALSE]
  index$score <- NULL
  index$priority <- NULL
  utils::head(index, max(1L, as.integer(limit)))
}

#' Palette modal
#' @keywords internal
palette_modal <- function() {
  modalDialog(
    title = NULL,
    htmltools::tags$div(
      class = "rcmdr-palette",
      htmltools::tags$label(
        class = "visually-hidden", `for` = "palette_query",
        tr("Search commands, help, data and history")
      ),
      textInput(
        "palette_query", NULL,
        placeholder = tr("Search commands, help, data and history..."),
        width = "100%"
      ),
      htmltools::tags$div(class = "rcmdr-palette-hint",
                          tr("Ctrl+K to open, Enter to run, Esc to close")),
      uiOutput("palette_results")
    ),
    footer = NULL,
    size = "l",
    easyClose = TRUE
  )
}

#' Palette results UI
#' @keywords internal
palette_results_ui <- function(results) {
  if (is.null(results) || nrow(results) == 0L) {
    return(empty_state(
      tr("No matches"),
      tr("Try a menu label, a help topic, a variable or a recent command.")
    ))
  }
  htmltools::tags$div(
    class = "rcmdr-palette-results", role = "listbox",
    lapply(seq_len(nrow(results)), function(i) {
      row <- results[i, , drop = FALSE]
      enabled <- isTRUE(row$enabled)
      htmltools::tags$button(
        type = "button",
        class = paste("rcmdr-palette-result", if (!enabled) "disabled"),
        role = "option",
        `aria-disabled` = if (enabled) NULL else "true",
        `data-palette-type` = row$type,
        `data-palette-id` = row$id,
        `data-palette-action` = if (row$type == "history") "rerun" else "run",
        `data-palette-enabled` = if (enabled) "true" else "false",
        onclick = "rcmdrPaletteClick(this); return false;",
        htmltools::tags$span(class = "rcmdr-palette-label", row$label),
        htmltools::tags$span(class = "rcmdr-palette-type", row$type),
        htmltools::tags$span(class = "rcmdr-palette-path", row$path),
        if (nzchar(row$reason %||% "")) {
          htmltools::tags$span(class = "rcmdr-palette-reason", row$reason)
        }
      )
    })
  )
}
