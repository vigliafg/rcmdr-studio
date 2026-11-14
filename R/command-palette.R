# Command palette ------------------------------------------------------------
#
# The palette is a searchable index over the menu tree, the dialogs, the help
# catalogue, datasets, variables, the structured history and the guided
# workflows.  It always runs the existing commands: it is a navigation layer,
# not a second command engine.  Favourites and recents are preferences, not
# commands.

palette_type_priority <- function() {
  c(workflow = 0L, menu = 1L, dialog = 1L, help = 2L, data = 3L,
    history = 5L)
}

palette_empty <- function() {
  data.frame(
    id = character(), type = character(), label = character(),
    path = character(), keywords = character(), enabled = logical(),
    reason = character(), command = character(), group = character(),
    favorite = logical(), recent = logical(), stringsAsFactors = FALSE
  )
}

palette_row <- function(id, type, label, path, keywords, enabled = TRUE,
                        reason = "", command = "", group = type,
                        favorite = FALSE, recent = FALSE) {
  data.frame(
    id = id, type = type, label = label, path = path, keywords = keywords,
    enabled = isTRUE(enabled), reason = reason %||% "", command = command,
    group = group, favorite = isTRUE(favorite), recent = isTRUE(recent),
    stringsAsFactors = FALSE
  )
}

#' Build the palette index
#' @keywords internal
palette_index <- function(state) {
  rows <- list()
  favorites <- menu_favorite_ids(state)
  recents <- menu_recent_ids(state)
  dialogs <- tryCatch(dialog_ids(), error = function(e) character())

  leaves <- menu_leaves(menu_tree())
  if (nrow(leaves) > 0L) {
    for (i in seq_len(nrow(leaves))) {
      row <- leaves[i, , drop = FALSE]
      status <- command_status(state, row$command, row$activation, row$install)
      if (identical(status, "hidden")) next
      is_dialog <- row$command %in% dialogs
      rows[[length(rows) + 1L]] <- palette_row(
        id = row$command,
        type = if (is_dialog) "dialog" else "menu",
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
        command = row$command,
        group = if (is_dialog) "dialog" else "menu",
        favorite = row$command %in% favorites,
        recent = row$command %in% recents
      )
    }
  }

  topics <- tryCatch(help_catalog(), error = function(e) NULL)
  if (!is.null(topics) && nrow(topics) > 0L) {
    for (i in seq_len(nrow(topics))) {
      topic <- topics[i, , drop = FALSE]
      rows[[length(rows) + 1L]] <- palette_row(
        id = topic$id,
        type = "help",
        label = topic$title,
        path = topic$category %||% "help",
        keywords = paste(topic$title, topic$category, topic$id),
        group = "help"
      )
    }
  }

  workflows <- if (isTRUE(feature_enabled(state, "workflows"))) {
    tryCatch(workflow_registry(), error = function(e) list())
  } else {
    list()
  }
  if (length(workflows) > 0L) {
    for (workflow in workflows) {
      rows[[length(rows) + 1L]] <- palette_row(
        id = workflow$id,
        type = "workflow",
        label = workflow$title,
        path = tr("Workflows"),
        keywords = paste(
          workflow$title, workflow$description,
          paste(vapply(workflow$steps, `[[`, character(1), "title"),
                collapse = " ")
        ),
        group = "workflow"
      )
    }
  }

  objects <- ls(envir = state$env)
  if (length(objects) > 0L) {
    datasets <- objects[vapply(objects, function(name) {
      is.data.frame(get(name, envir = state$env, inherits = FALSE))
    }, logical(1))]
    for (name in datasets) {
      rows[[length(rows) + 1L]] <- palette_row(
        id = name, type = "dataset", label = name, path = tr("Data"),
        keywords = paste(name, "dataset data frame"), group = "data"
      )
    }
  }

  vars <- variables(state)
  if (length(vars) > 0L) {
    dataset <- active_dataset(state) %||% ""
    for (name in vars) {
      rows[[length(rows) + 1L]] <- palette_row(
        id = name, type = "variable", label = name, path = dataset,
        keywords = paste(name, dataset, "variable"), group = "data"
      )
    }
  }

  history <- history_recent(state, 50L)
  if (length(history) > 0L) {
    for (entry in history) {
      rows[[length(rows) + 1L]] <- palette_row(
        id = entry$id, type = "history",
        label = history_command_label(entry),
        path = entry$source %||% "script",
        keywords = paste(entry$command %||% "", entry$source %||% ""),
        command = entry$command %||% "",
        group = "history",
        recent = (entry$command %||% "") %in% recents
      )
    }
  }

  if (length(rows) == 0L) return(palette_empty())
  do.call(rbind, rows)
}

#' Cached palette index
#'
#' The index is rebuilt only when the application state or the plugin registry
#' changes, so typing in the palette does not rebuild the menu tree.
#' @keywords internal
palette_index_cached <- function(state) {
  plugin_version <- tryCatch(.plugin_registry$version, error = function(e) 0L)
  key <- paste(state$revision %||% 0L, plugin_version, sep = ":")
  if (is.null(state$palette_cache) ||
      !identical(state$palette_cache_key, key)) {
    state$palette_cache <- palette_index(state)
    state$palette_cache_key <- key
  }
  state$palette_cache
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

palette_type_choices <- function() {
  stats::setNames(
    c("all", "menu", "dialog", "help", "data", "history", "workflow",
      "favorite"),
    c(tr("All types"), tr("Menus"), tr("Dialogs"), tr("Help"),
      tr("Data"), tr("History"), tr("Workflows"), tr("Favourites"))
  )
}

#' Filter palette rows by type
#' @keywords internal
palette_filter_type <- function(index, type = "all") {
  if (is.null(index) || nrow(index) == 0L) return(index)
  type <- type %||% "all"
  if (identical(type, "all")) return(index)
  if (identical(type, "favorite")) return(index[index$favorite, , drop = FALSE])
  if (identical(type, "data")) {
    return(index[index$group == "data", , drop = FALSE])
  }
  index[index$group == type, , drop = FALSE]
}

#' Search the palette index
#'
#' @param query Search query.
#' @param index Index returned by [palette_index()].
#' @param limit Maximum number of rows.
#' @param type Optional type filter (see [palette_type_choices()]).
#' @param favorites_only Keep only favourites.
#' @keywords internal
palette_search <- function(query, index, limit = 20L, type = "all",
                           favorites_only = FALSE) {
  if (is.null(index) || nrow(index) == 0L) return(index)
  query <- trimws(query %||% "")
  index <- palette_filter_type(index, type)
  if (nrow(index) == 0L) return(index)
  if (isTRUE(favorites_only)) {
    index <- index[index$favorite, , drop = FALSE]
    if (nrow(index) == 0L) return(index)
  }

  priorities <- palette_type_priority()
  index$priority <- unname(priorities[index$group] %||% 99L)

  if (!nzchar(query)) {
    index <- index[order(-index$favorite, -index$recent, !index$enabled,
                         index$priority, index$label), , drop = FALSE]
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
    index$priority <- NULL
    return(index)
  }
  # When a contiguous match exists, subsequence-only matches are usually noise
  # (for example "logist" matching "Plot geometric distribution").
  if (any(index$score >= 500)) {
    index <- index[index$score >= 500, , drop = FALSE]
  }
  index$score <- index$score +
    ifelse(index$favorite, 5000, 0) +
    ifelse(index$recent, 2000, 0)
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
      studio_breadcrumb(c(tr("Studio"), tr("Command palette"))),
      htmltools::tags$label(
        class = "visually-hidden", `for` = "palette_query",
        tr("Search commands, help, data and history")
      ),
      textInput(
        "palette_query", NULL,
        placeholder = tr("Search commands, help, data, variables, history or workflows..."),
        width = "100%"
      ),
      htmltools::tags$div(
        class = "rcmdr-palette-filters d-flex gap-2 align-items-end flex-wrap",
        htmltools::tags$div(
          style = "min-width: 150px;",
          selectInput("palette_type", NULL, choices = palette_type_choices(),
                      width = "150px")
        ),
        checkboxInput("palette_favorites", tr("Favourites only"), value = FALSE)
      ),
      htmltools::tags$div(class = "rcmdr-palette-hint",
                          tr("Ctrl+K to open, arrows to move, Enter to run, Esc to close")),
      uiOutput("palette_results")
    ),
    footer = NULL,
    size = "l",
    easyClose = TRUE
  )
}

palette_action_button <- function(row, action, label) {
  htmltools::tags$button(
    type = "button",
    class = "btn btn-sm btn-outline-secondary rcmdr-palette-action",
    `data-palette-action-name` = action,
    onclick = sprintf(
      "event.stopPropagation(); rcmdrPaletteAction(this, '%s'); return false;",
      action
    ),
    label
  )
}

palette_actions_ui <- function(row) {
  if (!isTRUE(row$enabled)) return(NULL)
  type <- row$type %||% "menu"
  buttons <- switch(
    type,
    menu = c(run = tr("Run")),
    dialog = c(open = tr("Open")),
    help = c(open = tr("Open")),
    dataset = c(activate = tr("Activate")),
    variable = c(suggest = tr("Suggest")),
    history = c(rerun = tr("Rerun"), insert = tr("Insert"), copy = tr("Copy")),
    workflow = c(start = tr("Start")),
    character()
  )
  if (type %in% c("menu", "dialog")) {
    buttons <- c(
      buttons,
      favorite = if (isTRUE(row$favorite)) tr("Unfavourite") else
        tr("Favourite")
    )
  }
  if (length(buttons) == 0L) return(NULL)
  htmltools::tags$div(
    class = "rcmdr-palette-actions",
    lapply(names(buttons), function(action) {
      palette_action_button(row, action, buttons[[action]])
    })
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
    `aria-label` = tr("Command palette results"),
    lapply(seq_len(nrow(results)), function(i) {
      row <- results[i, , drop = FALSE]
      enabled <- isTRUE(row$enabled)
      htmltools::tags$div(
        class = paste("rcmdr-palette-result", if (!enabled) "disabled"),
        role = "option",
        tabindex = "0",
        `aria-disabled` = if (enabled) NULL else "true",
        `data-palette-type` = row$type,
        `data-palette-id` = row$id,
        `data-palette-command` = row$command %||% "",
        `data-palette-action` = if (row$type == "history") "rerun" else "run",
        `data-palette-enabled` = if (enabled) "true" else "false",
        onclick = "rcmdrPaletteClick(this); return false;",
        htmltools::tags$div(
          class = "rcmdr-palette-main",
          htmltools::tags$span(
            class = "rcmdr-palette-type",
            if (isTRUE(row$favorite)) "\u2605" else row$type
          ),
          htmltools::tags$span(class = "rcmdr-palette-label", row$label),
          htmltools::tags$span(class = "rcmdr-palette-path", row$path),
          if (nzchar(row$reason %||% "")) {
            htmltools::tags$span(class = "rcmdr-palette-reason", row$reason)
          }
        ),
        palette_actions_ui(row)
      )
    })
  )
}
