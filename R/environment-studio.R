# Environment Studio ---------------------------------------------------------
#
# The Environment tab is the object explorer of the session.  It renders
# metadata only and never copies large objects; the preview uses `str()` and
# `summary()` outside the command engine, while every action that changes the
# session or prints output goes through run_command() and is therefore
# reproducible.

object_size_label <- function(object) {
  size <- tryCatch(format(utils::object.size(object), units = "auto"),
                   error = function(e) "")
  as.character(size)
}

object_preview_text <- function(object) {
  if (is.function(object)) {
    return(paste(utils::capture.output(args(object)), collapse = "\n"))
  }
  if (is.data.frame(object)) {
    lines <- utils::capture.output(
      utils::str(object, max.level = 1L, give.attr = FALSE, list.len = 8L)
    )
    return(paste(utils::head(lines, 12L), collapse = "\n"))
  }
  if (is.atomic(object) || is.list(object)) {
    lines <- utils::capture.output(
      utils::str(object, max.level = 1L, give.attr = FALSE, list.len = 8L)
    )
    return(paste(utils::head(lines, 12L), collapse = "\n"))
  }
  paste(class(object), collapse = ", ")
}

#' Objects in the session environment
#'
#' @return A data frame with `name`, `class`, `size`, `type` and `preview`.
#' @keywords internal
object_list <- function(state) {
  objects <- ls(envir = state$env)
  if (length(objects) == 0L) {
    return(data.frame(
      name = character(), class = character(), size = character(),
      type = character(), preview = character(), stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(objects, function(name) {
    object <- tryCatch(get(name, envir = state$env, inherits = FALSE),
                       error = function(e) NULL)
    if (is.null(object)) return(NULL)
    data.frame(
      name = name,
      class = paste(class(object), collapse = ", "),
      size = object_size_label(object),
      type = if (is.data.frame(object)) {
        sprintf("%d x %d", nrow(object), ncol(object))
      } else {
        typeof(object)
      },
      preview = object_preview_text(object),
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(data.frame(
      name = character(), class = character(), size = character(),
      type = character(), preview = character(), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

#' Preview an object without running a command
#' @keywords internal
object_preview <- function(state, name) {
  if (is.null(name) || !nzchar(name) ||
      !exists(name, envir = state$env, inherits = FALSE)) {
    return("")
  }
  object <- get(name, envir = state$env, inherits = FALSE)
  if (is.data.frame(object)) {
    lines <- c(
      paste0("str(", name, ")"),
      utils::capture.output(utils::str(object, max.level = 1L, give.attr = FALSE)),
      "",
      paste0("summary(", name, ")"),
      utils::capture.output(summary(object))
    )
    return(paste(utils::head(lines, 60L), collapse = "\n"))
  }
  lines <- utils::capture.output(
    utils::str(object, max.level = 1L, give.attr = FALSE, list.len = 10L)
  )
  paste(utils::head(lines, 40L), collapse = "\n")
}

#' Run an action on a session object
#'
#' `summary`, `str`, `plot` and `remove` execute through the normal command
#' engine; `view`, `activate_dataset` and `activate_model` are session
#' operations.  `preview` returns text and never runs a command.
#' @keywords internal
object_action <- function(state, name, action = "preview") {
  if (is.null(name) || !nzchar(name) ||
      !exists(name, envir = state$env, inherits = FALSE)) {
    return(list(ok = FALSE, message = tr("The object is not available.")))
  }
  object <- get(name, envir = state$env, inherits = FALSE)
  switch(
    action,
    preview = {
      state$environment_selection <- name
      state$environment_preview <- object_preview(state, name)
      list(ok = TRUE, preview = state$environment_preview)
    },
    view = {
      if (is.data.frame(object)) {
        dataset_activate(state, name)
        if (is.function(state$show_tab)) state$show_tab(tr("Data"))
        list(ok = TRUE, tab = tr("Data"))
      } else {
        state$environment_selection <- name
        state$environment_preview <- object_preview(state, name)
        list(ok = TRUE, preview = state$environment_preview)
      }
    },
    activate_dataset = {
      if (!is.data.frame(object)) {
        return(list(ok = FALSE, message = tr("The object is not a data set.")))
      }
      dataset_activate(state, name)
      list(ok = TRUE)
    },
    activate_model = {
      if (!model_is_object(object)) {
        return(list(ok = FALSE, message = tr("The object is not a model.")))
      }
      active_model(state, name)
      list(ok = TRUE)
    },
    summary = {
      run_command(state, paste0("summary(", name, ")"), source = "environment")
      list(ok = TRUE)
    },
    str = {
      run_command(state, paste0("str(", name, ")"), source = "environment")
      list(ok = TRUE)
    },
    plot = {
      run_command(state, paste0("plot(", name, ")"), source = "environment")
      list(ok = TRUE)
    },
    remove = {
      run_command(state, paste0("rm(", name, ")"), source = "environment")
      if (identical(state$active_dataset, name)) state$active_dataset <- NULL
      if (identical(state$active_model, name)) state$active_model <- NULL
      list(ok = TRUE)
    },
    save = {
      if (!is.function(state$open_dialog)) {
        return(list(ok = FALSE, message = "Dialogs are not available."))
      }
      open_dialog_memory(state, "environmentSave", list(object = name))
      list(ok = TRUE)
    },
    list(ok = FALSE, message = sprintf("Unknown action: %s", action))
  )
}

#' Save-object dialog
#' @keywords internal
environment_save_dialog <- function() {
  id <- "environmentSave"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Save object"), help_topic = "workbench",
    preview = TRUE,
    ui = function(state, memory) {
      objects <- ls(envir = state$env)
      choices <- if (length(objects) == 0L) {
        stats::setNames("", tr("<none>"))
      } else {
        stats::setNames(objects, objects)
      }
      selected <- memory$object %||% state$environment_selection %||%
        (if (length(objects) > 0L) objects[[1L]] else "")
      htmltools::tagList(
        selectInput(ns("object"), tr("Object"), choices = choices,
                    selected = selected, width = "100%"),
        entry_input(ns("path"), tr("Output file:"),
                    memory$path %||% file.path(getwd(), "object.rds")),
        selectInput(
          ns("format"), tr("Format"),
          choices = c("RDS" = "rds", "RData" = "rdata"),
          selected = memory$format %||% "rds", width = "100%"
        ),
        help_text(tr("The object is written by a reproducible R command."))
      )
    },
    on_ok = function(input, state) {
      object <- input[[ns("object")]] %||% ""
      path <- trim_blanks(input[[ns("path")]] %||% "")
      format <- input[[ns("format")]] %||% "rds"
      if (!nzchar(object) || !exists(object, envir = state$env, inherits = FALSE)) {
        return(list(error = tr("Choose an existing object.")))
      }
      if (!nzchar(path)) return(list(error = tr("Enter an output file.")))
      if (!dir.exists(dirname(path))) {
        return(list(error = sprintf(tr("Directory not found: %s"),
                                    dirname(path))))
      }
      quoted <- encodeString(path, quote = "\"")
      command <- if (identical(format, "rdata")) {
        sprintf("save(%s, file = %s)", object, quoted)
      } else {
        sprintf("saveRDS(%s, file = %s)", object, quoted)
      }
      list(
        commands = command,
        memory = list(object = object, path = path, format = format),
        message = sprintf(tr("Saving %s."), object)
      )
    }
  )
}

# UI -------------------------------------------------------------------------

environment_object_actions <- function(name) {
  htmltools::tags$div(
    class = "d-flex gap-1 flex-wrap",
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'preview'}, {priority: 'event'});",
        name
      ),
      tr("Preview")
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'view'}, {priority: 'event'});",
        name
      ),
      tr("View")
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'summary'}, {priority: 'event'});",
        name
      ),
      tr("Summary")
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'str'}, {priority: 'event'});",
        name
      ),
      tr("str")
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'save'}, {priority: 'event'});",
        name
      ),
      tr("Save")
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-danger",
      onclick = sprintf(
        "Shiny.setInputValue('environment_action', {name: '%s', action: 'remove'}, {priority: 'event'});",
        name
      ),
      tr("Remove")
    )
  )
}

#' Object explorer table
#' @keywords internal
environment_objects_ui <- function(state, query = "") {
  table <- object_list(state)
  if (nrow(table) == 0L) {
    return(empty_state(tr("The environment is empty"),
                       tr("Import a data set or run a command.")))
  }
  query <- tolower(trimws(query %||% ""))
  if (nzchar(query)) {
    table <- table[
      grepl(query, tolower(paste(table$name, table$class)), fixed = TRUE),
      , drop = FALSE
    ]
  }
  if (nrow(table) == 0L) {
    return(empty_state(tr("No matching objects")))
  }
  rows <- lapply(seq_len(nrow(table)), function(i) {
    row <- table[i, , drop = FALSE]
    htmltools::tags$tr(
      htmltools::tags$td(htmltools::tags$code(row$name[[1L]])),
      htmltools::tags$td(row$class[[1L]]),
      htmltools::tags$td(row$type[[1L]]),
      htmltools::tags$td(row$size[[1L]]),
      htmltools::tags$td(environment_object_actions(row$name[[1L]]))
    )
  })
  htmltools::tags$table(
    class = "table table-sm rcmdr-object-table",
    htmltools::tags$thead(htmltools::tags$tr(
      htmltools::tags$th(tr("Name")), htmltools::tags$th(tr("Class")),
      htmltools::tags$th(tr("Type")), htmltools::tags$th(tr("Size")),
      htmltools::tags$th(tr("Actions"))
    )),
    htmltools::tags$tbody(rows)
  )
}

#' Dataset registry table for the Environment tab
#' @keywords internal
environment_datasets_ui <- function(state) {
  registry <- dataset_registry(state)
  if (nrow(registry) == 0L) {
    return(empty_state(tr("No data sets"),
                       tr("Import a data set to see it here.")))
  }
  rows <- lapply(seq_len(nrow(registry)), function(i) {
    row <- registry[i, , drop = FALSE]
    htmltools::tags$tr(
      class = if (isTRUE(row$active[[1L]])) "table-active" else NULL,
      htmltools::tags$td(htmltools::tags$code(row$name[[1L]])),
      htmltools::tags$td(sprintf("%d x %d", row$rows[[1L]], row$cols[[1L]])),
      htmltools::tags$td(row$source[[1L]]),
      htmltools::tags$td(row$modified[[1L]]),
      htmltools::tags$td(
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-outline-secondary",
          onclick = sprintf(
            "Shiny.setInputValue('environment_action', {name: '%s', action: 'activate_dataset'}, {priority: 'event'});",
            row$name[[1L]]
          ),
          tr("Set active")
        )
      )
    )
  })
  htmltools::tags$table(
    class = "table table-sm",
    htmltools::tags$thead(htmltools::tags$tr(
      htmltools::tags$th(tr("Name")), htmltools::tags$th(tr("Size")),
      htmltools::tags$th(tr("Source")), htmltools::tags$th(tr("Modified")),
      htmltools::tags$th(tr("Actions"))
    )),
    htmltools::tags$tbody(rows)
  )
}

#' Environment workspace: objects, data sets and models
#' @keywords internal
environment_workspace_ui <- function() {
  htmltools::tagList(
    tabsetPanel(
      id = "environment_tabs",
      tabPanel(
        tr("Objects"),
        htmltools::div(
          class = "d-flex gap-2 align-items-center mb-2 flex-wrap",
          textInput("environment_filter", NULL,
                    placeholder = tr("Search objects..."), width = "230px"),
          actionButton("environment_refresh", tr("Refresh"),
                       class = "btn-sm btn-outline-secondary")
        ),
        uiOutput("environment_objects"),
        htmltools::tags$h6(class = "mt-3", tr("Preview")),
        uiOutput("environment_preview")
      ),
      tabPanel(
        tr("Data sets"),
        htmltools::div(
          class = "d-flex gap-2 mb-2",
          actionButton("environment_refresh_datasets", tr("Refresh"),
                       class = "btn-sm btn-outline-secondary")
        ),
        uiOutput("environment_datasets")
      ),
      tabPanel(
        tr("Models"),
        uiOutput("models_dashboard")
      )
    )
  )
}
