# Script Studio --------------------------------------------------------------
#
# The Script tab is the low-level R workspace.  It shares the document registry
# with the Report Studio: `state$documents` holds every open buffer and
# `state$active_document` points at the active one.  This module adds the
# workbench features on top of that shared model: document tabs, executable
# cells with run above/below, an outline, parse diagnostics, find/replace,
# formatting and autosave.
#
# Nothing here adds a statistical procedure.  Running a cell always goes
# through `run_command()`.

# Registry -------------------------------------------------------------------

#' Open documents as a script registry
#'
#' Every registry entry is usable from the Script tab; the Mode column tells
#' whether the buffer is a plain R script, an R Markdown document or a knitr
#' document.
#' @keywords internal
script_registry <- function(state) {
  table <- document_list(state)
  if (nrow(table) == 0L) {
    return(data.frame(
      id = character(), title = character(), path = character(),
      mode = character(), dirty = logical(), active = logical(),
      label = character(), stringsAsFactors = FALSE
    ))
  }
  table$label <- ifelse(
    table$dirty, paste0(table$title, " *"), table$title
  )
  table
}

#' Create a new plain R script
#' @keywords internal
script_create <- function(state, title = NULL, text = "") {
  title <- title %||% tr("Untitled script")
  current <- document(state)
  empty <- !nzchar(trimws(current$text %||% "")) &&
    !isTRUE(current$dirty) &&
    (is.null(current$path) || !nzchar(current$path %||% "")) &&
    identical(current$mode %||% "r", "r")
  if (empty && !is.null(state$active_document)) {
    current$title <- title
    current$text <- paste(text, collapse = "\n")
    current$path <- NULL
    current$mode <- "r"
    current$dirty <- FALSE
    document_store(state, current)
    document_enable_options(state, "r")
    document_mark_clean(state)
    state_touch(state)
    return(invisible(state$active_document))
  }
  document_create(
    state, mode = "r", title = title,
    text = paste(text, collapse = "\n"), dirty = FALSE, activate = TRUE
  )
}

#' Activate a document as the script buffer
#' @keywords internal
script_activate <- function(state, id) {
  if (is.null(id) || is.null(state$documents[[id]])) return(invisible(FALSE))
  document_activate(state, id)
  invisible(TRUE)
}

#' Close a document from the script tabs
#' @keywords internal
script_close <- function(state, id = state$active_document) {
  document_close(state, id)
}

# Cells ----------------------------------------------------------------------

script_empty_cells <- function() {
  data.frame(
    id = character(), label = character(), start = integer(),
    end = integer(), code = character(), stringsAsFactors = FALSE
  )
}

script_cell_label <- function(lines, start) {
  line <- trimws(lines[[start]] %||% "")
  if (grepl("^#", line)) {
    label <- trimws(sub("^#+", "", line))
    label <- trimws(sub("[-=]+$", "", label))
    if (nzchar(label)) return(label)
  }
  ""
}

# Include the comment block immediately above an expression in its cell, so a
# commented cell header travels with the code it documents.
script_cell_comment_start <- function(lines, start) {
  while (start > 1L) {
    previous <- trimws(lines[[start - 1L]])
    if (grepl("^#", previous) && !grepl("^#\\s*%%", previous)) {
      start <- start - 1L
    } else {
      break
    }
  }
  start
}

#' Split an R script into executable cells
#'
#' In plain R mode the cells follow the top-level expressions found by
#' `parse()`, so a multi-line call stays in one cell.  When the script does not
#' parse, a blank-line split keeps the editor usable.  In R Markdown and knitr
#' mode the cells are the code chunks.
#' @keywords internal
script_cells <- function(text, mode = "r") {
  text <- paste(text %||% "", collapse = "\n")
  if (!nzchar(trimws(text))) return(script_empty_cells())

  if (!identical(mode, "r")) {
    chunks <- document_chunks(text, mode)
    if (nrow(chunks) == 0L) return(script_empty_cells())
    return(data.frame(
      id = chunks$id,
      label = ifelse(nzchar(chunks$label), chunks$label,
                     sprintf(tr("Chunk %d"), seq_len(nrow(chunks)))),
      start = chunks$start,
      end = chunks$end,
      code = chunks$code,
      stringsAsFactors = FALSE
    ))
  }

  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  exprs <- tryCatch(
    parse(text = text, keep.source = TRUE),
    error = function(e) NULL
  )
  if (is.null(exprs) || length(exprs) == 0L) {
    return(script_cells_blank(lines))
  }
  srcrefs <- attr(exprs, "srcref")
  if (is.null(srcrefs) || length(srcrefs) != length(exprs)) {
    return(script_cells_blank(lines))
  }
  rows <- lapply(seq_along(exprs), function(i) {
    ref <- srcrefs[[i]]
    start <- as.integer(ref[[1L]])
    end <- as.integer(ref[[3L]])
    start <- script_cell_comment_start(lines, start)
    data.frame(
      id = sprintf("cell-%02d", i),
      label = script_cell_label(lines, start),
      start = start,
      end = end,
      code = paste(lines[seq.int(start, end)], collapse = "\n"),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

script_cells_blank <- function(lines) {
  rows <- list()
  start <- NULL
  flush <- function(end) {
    if (is.null(start) || end < start) return(invisible(NULL))
    code <- paste(lines[seq.int(start, end)], collapse = "\n")
    if (!nzchar(trimws(code))) return(invisible(NULL))
    rows[[length(rows) + 1L]] <<- data.frame(
      id = sprintf("cell-%02d", length(rows) + 1L),
      label = script_cell_label(lines, start),
      start = start,
      end = end,
      code = code,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
  for (i in seq_along(lines)) {
    if (!nzchar(trimws(lines[[i]]))) {
      if (!is.null(start)) {
        flush(i - 1L)
        start <- NULL
      }
    } else if (is.null(start)) {
      start <- i
    }
  }
  if (!is.null(start)) flush(length(lines))
  if (length(rows) == 0L) return(script_empty_cells())
  do.call(rbind, rows)
}

#' Cell containing a zero-based editor row
#' @keywords internal
script_cell_at <- function(cells, row) {
  if (is.null(cells) || nrow(cells) == 0L) return(NULL)
  line <- as.integer(row %||% 0L) + 1L
  for (i in seq_len(nrow(cells))) {
    if (line >= cells$start[[i]] && line <= cells$end[[i]]) {
      return(cells[i, , drop = FALSE])
    }
  }
  NULL
}

#' Cells above a zero-based editor row
#' @keywords internal
script_cells_above <- function(cells, row) {
  if (is.null(cells) || nrow(cells) == 0L) return(script_empty_cells())
  line <- as.integer(row %||% 0L) + 1L
  cells[cells$end < line, , drop = FALSE]
}

#' Cells below a zero-based editor row
#' @keywords internal
script_cells_below <- function(cells, row) {
  if (is.null(cells) || nrow(cells) == 0L) return(script_empty_cells())
  line <- as.integer(row %||% 0L) + 1L
  cells[cells$start > line, , drop = FALSE]
}

#' Execute code for the Script tab
#'
#' The code is logged only through the structured history (`log = FALSE`), so
#' the auto-append option cannot duplicate a cell into the script.
#' @keywords internal
script_execute <- function(state, code, source = "script") {
  if (is.null(code) || !nzchar(trimws(paste(code, collapse = "\n")))) {
    return(NULL)
  }
  result <- tryCatch(
    run_command(state, code, log = FALSE, source = source),
    error = function(e) {
      list(status = "error", error = conditionMessage(e),
           output = character(), messages = character(),
           warnings = character())
    }
  )
  result
}

#' Run one cell and store its inline output
#' @keywords internal
script_run_cell <- function(state, cell) {
  if (is.null(cell) || nrow(cell) == 0L) return(NULL)
  result <- script_execute(state, cell$code[[1L]])
  if (is.null(result)) return(NULL)
  entry <- list(
    id = cell$id[[1L]],
    code = cell$code[[1L]],
    status = result$status %||% "ok",
    output = result$output %||% character(),
    messages = result$messages %||% character(),
    warnings = result$warnings %||% character(),
    error = result$error %||% NULL,
    time = Sys.time()
  )
  state$script_outputs[[cell$id[[1L]]]] <- entry
  entry
}

#' Run cells and store each output
#' @keywords internal
script_run_cells <- function(state, cells) {
  if (is.null(cells) || nrow(cells) == 0L) return(invisible(list()))
  results <- lapply(seq_len(nrow(cells)), function(i) {
    script_run_cell(state, cells[i, , drop = FALSE])
  })
  names(results) <- cells$id
  invisible(results)
}

# Outline and diagnostics ---------------------------------------------------

#' Outline of an R script
#'
#' Headings are R comments such as `# Section`, `# ---- Section ----` and
#' `# %%`; function definitions are included as level-2 entries.
#' @keywords internal
script_outline <- function(text, mode = "r") {
  if (!identical(mode, "r")) return(document_outline(text, mode))
  lines <- strsplit(paste(text %||% "", collapse = "\n"), "\n", fixed = TRUE)[[1L]]
  empty <- data.frame(level = integer(), title = character(),
                      line = integer(), stringsAsFactors = FALSE)
  rows <- list()
  for (i in seq_along(lines)) {
    line <- lines[[i]]
    if (grepl("^\\s*#\\s*%%", line)) {
      title <- trimws(sub("^\\s*#\\s*%%\\s*", "", line))
      rows[[length(rows) + 1L]] <- data.frame(
        level = 1L, title = if (nzchar(title)) title else tr("Cell"),
        line = i, stringsAsFactors = FALSE
      )
      next
    }
    if (grepl("^\\s*#\\s*[-=]{2,}", line)) {
      title <- trimws(gsub("[-=]", "", sub("^\\s*#", "", line)))
      if (nzchar(title)) {
        rows[[length(rows) + 1L]] <- data.frame(
          level = 1L, title = title, line = i, stringsAsFactors = FALSE
        )
      }
      next
    }
    if (grepl("^#+\\s+\\S", line)) {
      title <- trimws(sub("^#+\\s*", "", line))
      level <- if (grepl("^##+\\s", line)) 2L else 1L
      if (nzchar(title)) {
        rows[[length(rows) + 1L]] <- data.frame(
          level = level, title = title, line = i, stringsAsFactors = FALSE
        )
      }
      next
    }
    hit <- regmatches(
      line,
      regexec("^\\s*([A-Za-z.][A-Za-z0-9._]*)\\s*<-\\s*function\\s*\\(", line)
    )[[1L]]
    if (length(hit) == 2L) {
      rows[[length(rows) + 1L]] <- data.frame(
        level = 2L, title = paste0(hit[[2L]], "()"), line = i,
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(rows) == 0L) return(empty)
  do.call(rbind, rows)
}

#' Parse diagnostics for an R script
#'
#' Returns a data frame with `line`, `column`, `severity` and `message`.  An
#' unparsable script produces an `error` row at the reported position.
#' @keywords internal
script_diagnostics <- function(text) {
  text <- paste(text %||% "", collapse = "\n")
  empty <- data.frame(line = integer(), column = integer(),
                      severity = character(), message = character(),
                      stringsAsFactors = FALSE)
  if (!nzchar(trimws(text))) return(empty)
  result <- tryCatch(
    {
      parse(text = text)
      NULL
    },
    error = function(e) e
  )
  if (is.null(result)) return(empty)
  message <- conditionMessage(result)
  line <- 1L
  column <- 1L
  hit <- regmatches(message, regexec(":([0-9]+):([0-9]+):", message))[[1L]]
  if (length(hit) == 3L) {
    line <- as.integer(hit[[2L]])
    column <- as.integer(hit[[3L]])
  } else {
    hit <- regmatches(message, regexec("line ([0-9]+)", message))[[1L]]
    if (length(hit) == 2L) line <- as.integer(hit[[2L]])
  }
  data.frame(
    line = line, column = column, severity = "error",
    message = message, stringsAsFactors = FALSE
  )
}

#' Format a script with styler when available
#' @return A list with `text`, `changed` and `message`.
#' @keywords internal
script_format_text <- function(text) {
  text <- paste(text %||% "", collapse = "\n")
  if (!requireNamespace("styler", quietly = TRUE)) {
    return(list(text = text, changed = FALSE,
                message = tr("Install the styler package to format scripts.")))
  }
  formatted <- tryCatch(
    paste(styler::style_text(text), collapse = "\n"),
    error = function(e) e
  )
  if (inherits(formatted, "error")) {
    return(list(text = text, changed = FALSE,
                message = conditionMessage(formatted)))
  }
  list(text = formatted, changed = !identical(formatted, text), message = "")
}

#' Completion words for the Ace editor
#'
#' The list combines objects in the session, their columns and the names of the
#' registered data sets and models.
#' @keywords internal
script_completion_words <- function(state) {
  objects <- ls(envir = state$env)
  words <- objects
  for (name in objects) {
    object <- tryCatch(get(name, envir = state$env, inherits = FALSE),
                       error = function(e) NULL)
    if (is.data.frame(object)) {
      words <- c(words, paste0(name, "$", names(object)))
    } else if (inherits(object, "lm") || inherits(object, "glm")) {
      words <- c(words, sprintf("summary(%s)", name))
    }
  }
  unique(words[nzchar(words)])
}

# UI -------------------------------------------------------------------------

script_document_tabs_ui <- function(state) {
  table <- script_registry(state)
  if (nrow(table) == 0L) return(NULL)
  htmltools::div(
    class = "rcmdr-doc-tabs",
    lapply(seq_len(nrow(table)), function(i) {
      row <- table[i, , drop = FALSE]
      htmltools::tags$span(
        class = paste0(
          "rcmdr-doc-tab",
          if (isTRUE(row$active[[1L]])) " active" else ""
        ),
        htmltools::tags$a(
          href = "#",
          onclick = sprintf(
            "Shiny.setInputValue('script_tab_action', {id: '%s', action: 'activate'}, {priority: 'event'}); return false;",
            row$id[[1L]]
          ),
          htmltools::tags$span(class = "rcmdr-doc-mode",
                               toupper(row$mode[[1L]])),
          htmltools::tags$span(class = "rcmdr-doc-title",
                               row$label[[1L]])
        ),
        htmltools::tags$button(
          type = "button", class = "rcmdr-doc-close",
          title = tr("Close"),
          onclick = sprintf(
            "Shiny.setInputValue('script_tab_action', {id: '%s', action: 'close'}, {priority: 'event'}); return false;",
            row$id[[1L]]
          ),
          "\u00d7"
        )
      )
    }),
    htmltools::tags$button(
      type = "button", class = "rcmdr-doc-new", title = tr("New script"),
      onclick = "Shiny.setInputValue('script_new', Math.random(), {priority: 'event'});",
      "+"
    )
  )
}

#' Script Studio toolbar and workspace
#' @keywords internal
script_studio_ui <- function() {
  htmltools::tagList(
    uiOutput("script_tabs_ui"),
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      selectInput(
        "document_mode", NULL,
        choices = stats::setNames(
          c("r", "rmd", "rnw"),
          c(tr("R script"), tr("R Markdown"), tr("knitr"))
        ),
        selected = "r", width = "140px"
      ),
      actionButton("document_open", tr("Open"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save", tr("Save"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_save_as", tr("Save as"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_section", tr("Section"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_chunk", tr("Chunk"), class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_block", tr("Remove block"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_remove_section", tr("Remove section"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("document_knit", tr("Knit"), class = "btn-sm btn-primary")
    ),
    htmltools::div(
      class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
      actionButton("run_selection", tr("Run selection"), class = "btn-sm btn-primary"),
      actionButton("run_all", tr("Run all"), class = "btn-sm btn-outline-primary"),
      actionButton("run_cell", tr("Run cell"), class = "btn-sm btn-outline-primary",
                   onclick = "rcmdrScriptRunAt('run_cell_request');"),
      actionButton("run_above", tr("Run above"), class = "btn-sm btn-outline-secondary",
                   onclick = "rcmdrScriptRunAt('run_above_request');"),
      actionButton("run_below", tr("Run below"), class = "btn-sm btn-outline-secondary",
                   onclick = "rcmdrScriptRunAt('run_below_request');"),
      actionButton("run_chunk", tr("Run chunk at cursor"),
                   class = "btn-sm btn-outline-secondary",
                   onclick = "rcmdrRunChunk();"),
      actionButton("script_format", tr("Format"), class = "btn-sm btn-outline-secondary"),
      actionButton("clear_script", tr("Clear"), class = "btn-sm btn-outline-secondary"),
      downloadButton("download_script", tr("Download"),
                     class = "btn-sm btn-outline-secondary"),
      checkboxInput("auto_append", tr("Append generated commands"), value = TRUE)
    ),
    htmltools::div(
      class = "rcmdr-script-workspace row g-2",
      htmltools::div(
        class = "col-xl-9",
        htmltools::div(
          class = "rcmdr-script-findbar",
          textInput("script_find", NULL, placeholder = tr("Find..."), width = "170px"),
          textInput("script_replace", NULL, placeholder = tr("Replace with..."),
                    width = "170px"),
          actionButton("script_find_next", tr("Find"), class = "btn-sm btn-outline-secondary",
                       onclick = "rcmdrScriptFind();"),
          actionButton("script_replace_one", tr("Replace"), class = "btn-sm btn-outline-secondary",
                       onclick = "rcmdrScriptReplace(false);"),
          actionButton("script_replace_all", tr("Replace all"),
                       class = "btn-sm btn-outline-secondary",
                       onclick = "rcmdrScriptReplace(true);")
        ),
        uiOutput("script_editor_ui"),
        uiOutput("script_cell_output")
      ),
      htmltools::div(
        class = "col-xl-3",
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Outline")),
          uiOutput("script_outline")
        ),
        htmltools::div(
          class = "rcmdr-section-card",
          htmltools::tags$h6(tr("Diagnostics")),
          uiOutput("script_diagnostics")
        )
      )
    )
  )
}

script_output_card <- function(entry) {
  if (is.null(entry)) return(NULL)
  badge <- switch(
    entry$status %||% "ok",
    ok = htmltools::tags$span(class = "badge bg-success", tr("ok")),
    error = htmltools::tags$span(class = "badge bg-danger", tr("error")),
    htmltools::tags$span(class = "badge bg-secondary", entry$status %||% "ok")
  )
  lines <- c(entry$output %||% character(), entry$messages %||% character())
  htmltools::div(
    class = "rcmdr-cell-card",
    htmltools::div(
      class = "d-flex justify-content-between align-items-center gap-2",
      htmltools::tags$span(class = "small", entry$id %||% ""),
      htmltools::div(class = "d-flex gap-1 align-items-center", badge,
                     htmltools::tags$span(
                       class = "rcmdr-history-time",
                       format(entry$time %||% Sys.time(), "%H:%M:%S")
                     ))
    ),
    if (length(lines) > 0L) {
      htmltools::tags$pre(class = "rcmdr-script-output",
                          paste(lines, collapse = "\n"))
    },
    if (!is.null(entry$error)) {
      htmltools::tags$p(class = "text-danger small mb-0", entry$error)
    }
  )
}

# Server ---------------------------------------------------------------------

#' Script Studio server
#'
#' The module owns the document tabs, the outline, the diagnostics, the cell
#' output and the editor helpers.  The historical `run_all` and `run_selection`
#' handlers stay in `app_server()` to preserve the single-buffer behaviour.
#' @keywords internal
script_studio_server <- function(input, output, session, state, refresh,
                                 tick = NULL, run_code = NULL) {
  tick_reactive <- if (is.function(tick)) tick else reactiveVal(0L)
  revision <- reactiveVal(0L)
  bump <- function(global = FALSE) {
    revision(revision() + 1L)
    if (isTRUE(global) && is.function(refresh)) refresh()
    invisible(NULL)
  }

  current_text <- function() {
    value <- isolate(input$script)
    if (!is.null(value) && nzchar(value)) document_set_text(state, value)
    document_text(state)
  }

  output$script_tabs_ui <- renderUI({
    tick_reactive()
    revision()
    script_document_tabs_ui(state)
  })

  observeEvent(input$script_tab_action, {
    action <- input$script_tab_action
    id <- action$id %||% ""
    if (!nzchar(id)) return()
    if (identical(action$action %||% "", "close")) {
      current_text()
      script_close(state, id)
    } else {
      current_text()
      script_activate(state, id)
    }
    sync_editor_local()
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  sync_editor_local <- function() {
    value <- document_text(state)
    shinyAce::updateAceEditor(
      session, "script", value = value,
      mode = document_ace_mode(document_mode(state))
    )
  }

  # The Report Studio can change the shared buffer while the Script tab is
  # hidden; refresh the editor when the tab becomes visible again.
  observeEvent(input$main_tabs, {
    if (identical(input$main_tabs, "Script")) sync_editor_local()
  }, ignoreInit = TRUE)

  observeEvent(input$script_new, {
    current_text()
    script_create(state)
    sync_editor_local()
    bump(global = TRUE)
  }, ignoreInit = TRUE)

  text_debounced <- debounce(reactive({
    input$script
    document_text(state)
  }), 400)

  output$script_outline <- renderUI({
    revision()
    text_value <- text_debounced()
    outline <- script_outline(text_value, document_mode(state))
    if (nrow(outline) == 0L) {
      return(help_text(tr("No headings yet. Use `# Section` or `# %%` to add one.")))
    }
    htmltools::div(
      class = "rcmdr-report-outline",
      lapply(seq_len(nrow(outline)), function(i) {
        row <- outline[i, , drop = FALSE]
        htmltools::tags$a(
          href = "#",
          class = sprintf("rcmdr-outline-level-%d", row$level),
          onclick = sprintf(
            "window.rcmdrScriptGoto(%d); return false;", row$line - 1L
          ),
          row$title
        )
      })
    )
  })

  output$script_diagnostics <- renderUI({
    revision()
    diagnostics <- script_diagnostics(text_debounced())
    if (nrow(diagnostics) == 0L) {
      return(htmltools::tags$p(
        class = "text-success small mb-0", tr("The script parses correctly.")
      ))
    }
    htmltools::div(
      class = "rcmdr-script-diagnostics",
      lapply(seq_len(nrow(diagnostics)), function(i) {
        row <- diagnostics[i, , drop = FALSE]
        htmltools::tags$div(
          class = "small text-danger",
          sprintf(tr("Line %d, column %d"), row$line, row$column),
          htmltools::tags$span(" "),
          row$message
        )
      })
    )
  })

  output$script_cell_output <- renderUI({
    revision()
    tick_reactive()
    outputs <- state$script_outputs %||% list()
    if (length(outputs) == 0L) return(NULL)
    htmltools::div(
      class = "rcmdr-script-outputs",
      lapply(utils::tail(outputs, 5L), script_output_card)
    )
  })

  run_cells_quiet <- function(cells) {
    if (is.null(cells) || nrow(cells) == 0L) {
      showNotification(tr("There is no cell to run."), type = "message", duration = 3)
      return(invisible(FALSE))
    }
    for (i in seq_len(nrow(cells))) {
      script_run_cell(state, cells[i, , drop = FALSE])
    }
    bump(global = TRUE)
    invisible(TRUE)
  }

  observeEvent(input$run_cell_request, {
    text_value <- current_text()
    cells <- script_cells(text_value, document_mode(state))
    row <- input$run_cell_request$row %||% 0L
    cell <- script_cell_at(cells, row)
    if (is.null(cell) || nrow(cell) == 0L) cell <- cells
    run_cells_quiet(cell)
  }, ignoreInit = TRUE)

  observeEvent(input$run_above_request, {
    text_value <- current_text()
    cells <- script_cells(text_value, document_mode(state))
    row <- input$run_above_request$row %||% 0L
    run_cells_quiet(script_cells_above(cells, row))
  }, ignoreInit = TRUE)

  observeEvent(input$run_below_request, {
    text_value <- current_text()
    cells <- script_cells(text_value, document_mode(state))
    row <- input$run_below_request$row %||% 0L
    run_cells_quiet(script_cells_below(cells, row))
  }, ignoreInit = TRUE)

  # Clear inline output when the text changes: cell ids are positional.
  observeEvent(input$script, {
    if (length(state$script_outputs %||% list()) > 0L) {
      state$script_outputs <- list()
      revision(revision() + 1L)
    }
  }, ignoreInit = TRUE)

  observeEvent(input$script_format, {
    result <- script_format_text(current_text())
    if (isTRUE(result$changed)) {
      document_set_text(state, result$text)
      sync_editor_local()
      bump(global = TRUE)
      showNotification(tr("Script formatted."), type = "message", duration = 3)
    } else if (nzchar(result$message)) {
      showNotification(result$message, type = "message", duration = 6)
    } else {
      showNotification(tr("The script is already formatted."),
                       type = "message", duration = 3)
    }
  }, ignoreInit = TRUE)

  # Completion words are pushed only when they change.
  sent_words <- ""
  observe({
    tick_reactive()
    words <- script_completion_words(state)
    key <- paste(words, collapse = "|")
    if (!identical(key, sent_words)) {
      sent_words <<- key
      session$sendCustomMessage("rcmdr-completions", words)
    }
  })

  # Autosave: the Report Studio already saves dirty documents on its own
  # timer; this one covers the Script tab and is scoped to its visibility.
  autosave_timer <- reactiveTimer(state$options$autosave_interval %||% 30000L)
  observeEvent(autosave_timer(), {
    if (identical(input$main_tabs, "Script") && document_dirty(state)) {
      document_autosave(state)
      bump()
    }
  }, ignoreInit = TRUE)

  invisible(NULL)
}
