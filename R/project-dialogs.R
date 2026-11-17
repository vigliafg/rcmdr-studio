# Project dialogs and Home card ---------------------------------------------
#
# Project persistence is a session-level feature: it never generates a
# statistical command.  The dialogs only call the functions in `project.R`,
# and the Home card is a thin view over `project_summary()` and
# `project_recent()`.

project_roots <- function(state) {
  roots <- c(home = "~", wd = getwd(), root = "/")
  if (!is.null(state$project_path) && nzchar(state$project_path)) {
    roots <- c(project = dirname(state$project_path), roots)
  }
  roots
}

project_ensure_extension <- function(path) {
  path <- trimws(path %||% "")
  if (!nzchar(path)) return(path)
  if (!grepl(paste0("\\.", project_extension(), "$"), path,
             ignore.case = TRUE)) {
    path <- paste0(path, ".", project_extension())
  }
  path
}

project_new_dialog <- function() {
  id <- "projectNew"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("New project"), help_topic = "projects",
    preview = FALSE,
    ui = function(state, memory) {
      default <- memory$path %||%
        file.path(getwd(), project_file_name(tr("Untitled project")))
      htmltools::tagList(
        textInput(
          ns("title"), tr("Project title"),
          value = memory$title %||% tr("Untitled project")
        ),
        file_save_input(
          ns("path"), tr("Project file:"), default,
          filename = project_file_name(tr("Untitled project")),
          filetypes = c("rcmdrproj")
        ),
        checkboxInput(
          ns("history"), tr("Include the command history"),
          value = isTRUE(state$options$project_history)
        ),
        help_text(tr(
          "A project stores the data set sources, documents, plots and preferences. The statistical commands are not changed."
        ))
      )
    },
    observers = function(input, output, session, state, refresh) {
      file_save_observers(
        input, session, ns("path"), project_roots(state),
        guard = function() identical(state$current_dialog, id),
        filetypes = c("rcmdrproj"),
        defaultPath = getwd()
      )
    },
    on_ok = function(input, state) {
      path <- project_ensure_extension(input[[ns("path")]] %||% "")
      if (!nzchar(path)) {
        return(list(error = tr("Choose a project file name.")))
      }
      title <- trim_blanks(input[[ns("title")]] %||% "")
      if (!nzchar(title)) title <- sub(paste0("\\.", project_extension(), "$"),
                                       "", basename(path))
      state$options$project_history <- isTRUE(input[[ns("history")]])
      result <- tryCatch({
        project_reset(state, path = path, title = title)
        project_save(state, path = path,
                     include_history = isTRUE(input[[ns("history")]]))
      }, error = function(e) e)
      if (inherits(result, "error")) {
        return(list(error = conditionMessage(result)))
      }
      list(
        tab = tr("Home"),
        memory = list(path = path, title = title),
        message = sprintf(tr("Created project %s."), basename(path))
      )
    }
  )
}

project_open_dialog <- function() {
  id <- "projectOpen"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Open project"), help_topic = "projects",
    preview = FALSE,
    ui = function(state, memory) {
      recent <- project_recent(limit = 8L, file = state$project_recent_file)
      choices <- if (nrow(recent) > 0L) {
        stats::setNames(
          recent$path,
          sprintf("%s (%s)", recent$title, recent$path)
        )
      } else {
        character()
      }
      htmltools::tagList(
        if (length(choices) > 0L) {
          selectInput(
            ns("recent"), tr("Recent projects"), choices = c(stats::setNames("", tr("Choose a recent project")), choices),
            selected = memory$recent %||% ""
          )
        },
        file_input(
          ns("path"), tr("Project file:"), memory$path %||% "",
          filetypes = c("rcmdrproj")
        ),
        help_text(tr(
          "Opening a project restores its data sets, documents, plots and preferences. Save the current work first if it is not in a project."
        ))
      )
    },
    observers = function(input, output, session, state, refresh) {
      file_input_observers(
        input, session, ns("path"), project_roots(state),
        guard = function() identical(state$current_dialog, id),
        filetypes = c("rcmdrproj")
      )
    },
    on_ok = function(input, state) {
      path <- trim_blanks(input[[ns("path")]] %||% "")
      if (!nzchar(path)) path <- input[[ns("recent")]] %||% ""
      if (!nzchar(path)) return(list(error = tr("Choose a project file.")))
      result <- tryCatch(project_load(state, path), error = function(e) e)
      if (inherits(result, "error")) {
        return(list(error = conditionMessage(result)))
      }
      if (is.function(state$sync_document)) state$sync_document()
      list(
        tab = tr("Home"),
        memory = list(path = path),
        message = sprintf(tr("Opened project %s."), basename(path))
      )
    }
  )
}

project_save_as_dialog <- function() {
  id <- "projectSaveAs"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Save project as"), help_topic = "projects",
    preview = FALSE,
    ui = function(state, memory) {
      default <- memory$path %||% state$project_path %||%
        file.path(getwd(), project_file_name(
          state$project_title %||% tr("Untitled project")
        ))
      htmltools::tagList(
        file_save_input(
          ns("path"), tr("Project file:"), default,
          filename = project_file_name(
            state$project_title %||% tr("Untitled project")
          ),
          filetypes = c("rcmdrproj")
        ),
        checkboxInput(
          ns("history"), tr("Include the command history"),
          value = isTRUE(state$options$project_history)
        )
      )
    },
    observers = function(input, output, session, state, refresh) {
      file_save_observers(
        input, session, ns("path"), project_roots(state),
        guard = function() identical(state$current_dialog, id),
        filetypes = c("rcmdrproj"),
        defaultPath = dirname(state$project_path %||% getwd())
      )
    },
    on_ok = function(input, state) {
      path <- project_ensure_extension(input[[ns("path")]] %||% "")
      if (!nzchar(path)) {
        return(list(error = tr("Choose a project file name.")))
      }
      include <- isTRUE(input[[ns("history")]])
      state$options$project_history <- include
      result <- tryCatch(
        project_save_as(state, path, include_history = include),
        error = function(e) e
      )
      if (inherits(result, "error")) {
        return(list(error = conditionMessage(result)))
      }
      list(
        tab = tr("Home"),
        memory = list(path = path),
        message = sprintf(tr("Saved project %s."), basename(path))
      )
    }
  )
}

project_bundle_dialog <- function() {
  id <- "projectBundle"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Export project bundle"), help_topic = "projects",
    preview = FALSE,
    ui = function(state, memory) {
      default <- memory$path %||%
        file.path(getwd(), paste0(
          sub(paste0("\\.", project_extension(), "$"), "",
              project_file_name(state$project_title %||% "project")),
          "-bundle.tar.gz"
        ))
      htmltools::tagList(
        file_save_input(
          ns("path"), tr("Bundle file:"), default,
          filename = "project-bundle.tar.gz",
          filetypes = c("tar.gz", "tgz", "zip")
        ),
        help_text(tr(
          "The bundle contains the project file, the included data sets and the plot images. Use .tar.gz with base R; .zip needs the zip executable."
        ))
      )
    },
    observers = function(input, output, session, state, refresh) {
      file_save_observers(
        input, session, ns("path"), project_roots(state),
        guard = function() identical(state$current_dialog, id),
        filetypes = c("tar.gz", "tgz", "zip"),
        defaultPath = getwd()
      )
    },
    on_ok = function(input, state) {
      path <- trim_blanks(input[[ns("path")]] %||% "")
      if (!nzchar(path)) return(list(error = tr("Choose a bundle file name.")))
      if (!grepl("\\.(tar\\.gz|tgz|zip)$", path, ignore.case = TRUE)) {
        path <- paste0(path, ".tar.gz")
      }
      result <- tryCatch(project_export_bundle(state, path),
                         error = function(e) e)
      if (inherits(result, "error")) {
        return(list(error = conditionMessage(result)))
      }
      list(
        tab = tr("Home"),
        memory = list(path = path),
        message = sprintf(tr("Exported bundle %s."), basename(path))
      )
    }
  )
}

session_checkpoint_dialog <- function() {
  id <- "sessionCheckpoint"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Session checkpoints"), help_topic = "projects",
    preview = FALSE,
    ui = function(state, memory) {
      table <- session_checkpoint_list(state)
      htmltools::tagList(
        textInput(ns("label"), tr("Checkpoint label"), value = ""),
        actionButton(ns("create"), tr("Create checkpoint"),
                     class = "btn-sm btn-outline-primary"),
        htmltools::tags$hr(),
        if (nrow(table) == 0L) {
          empty_state(tr("No session checkpoints"),
                      tr("A checkpoint stores the active data set, model and documents."))
        } else {
          tableOutput(ns("table"))
        },
        if (nrow(table) > 0L) {
          htmltools::tags$div(
            class = "d-flex gap-2 align-items-end",
            selectInput(
              ns("checkpoint"), tr("Checkpoint"),
              choices = stats::setNames(
                table$id,
                sprintf("%s - %s", table$time, table$label)
              ),
              selected = memory$checkpoint %||% table$id[[1L]]
            ),
            actionButton(ns("restore"), tr("Restore"),
                         class = "btn-sm btn-outline-secondary"),
            actionButton(ns("delete"), tr("Delete"),
                         class = "btn-sm btn-outline-danger")
          )
        }
      )
    },
    observers = function(input, output, session, state, refresh) {
      output[[ns("table")]] <- renderTable({
        refresh()
        session_checkpoint_list(state)
      }, striped = TRUE, bordered = TRUE, spacing = "s")

      observeEvent(input[[ns("create")]], {
        if (!identical(state$current_dialog, id)) return()
        session_checkpoint_create(state, input[[ns("label")]] %||% "")
        refresh(refresh() + 1L)
      }, ignoreInit = TRUE)

      observeEvent(input[[ns("restore")]], {
        if (!identical(state$current_dialog, id)) return()
        checkpoint_id <- input[[ns("checkpoint")]] %||% ""
        if (!nzchar(checkpoint_id)) return()
        if (session_checkpoint_restore(state, checkpoint_id)) {
          showNotification(tr("Checkpoint restored."), type = "message")
          if (is.function(state$sync_document)) state$sync_document()
        }
        refresh(refresh() + 1L)
      }, ignoreInit = TRUE)

      observeEvent(input[[ns("delete")]], {
        if (!identical(state$current_dialog, id)) return()
        checkpoint_id <- input[[ns("checkpoint")]] %||% ""
        if (!nzchar(checkpoint_id)) return()
        session_checkpoint_delete(state, checkpoint_id)
        refresh(refresh() + 1L)
      }, ignoreInit = TRUE)
    },
    on_ok = function(input, state) {
      checkpoint_id <- input[[ns("checkpoint")]] %||% ""
      list(
        memory = list(checkpoint = checkpoint_id),
        message = tr("Session checkpoints are available from Tools.")
      )
    }
  )
}

# -- Home card ---------------------------------------------------------------

project_recovery_modal <- function(info, title = NULL) {
  shiny::modalDialog(
    title = title %||% tr("Recover unsaved project"),
    htmltools::tagList(
      htmltools::tags$p(sprintf(
        tr("An autosave newer than the project was found: %s."),
        info$path
      )),
      htmltools::tags$ul(
        class = "small",
        htmltools::tags$li(sprintf(
          tr("Autosave: %s (%s bytes)"),
          format(info$autosave_time, "%Y-%m-%d %H:%M:%S"),
          format(info$autosave_size, big.mark = " ")
        )),
        htmltools::tags$li(sprintf(
          tr("Project: %s"),
          if (is.na(info$project_time)) {
            tr("missing")
          } else {
            format(info$project_time, "%Y-%m-%d %H:%M:%S")
          }
        ))
      )
    ),
    footer = htmltools::tagList(
      actionButton("project_recovery_recover", tr("Recover"),
                   class = "btn-sm btn-primary"),
      actionButton("project_recovery_ignore", tr("Ignore"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("project_recovery_delete", tr("Delete autosave"),
                   class = "btn-sm btn-outline-danger"),
      modalButton(tr("Close"))
    ),
    easyClose = FALSE
  )
}

project_home_ui <- function(state) {
  summary <- project_summary(state)
  recent <- project_recent(limit = 5L, file = state$project_recent_file)
  recent_choices <- if (nrow(recent) > 0L) {
    stats::setNames(recent$path, sprintf("%s (%s)", recent$title, recent$path))
  } else {
    character()
  }

  htmltools::tags$div(
    class = "rcmdr-home-card",
    card_head(htmltools::tags$h5(tr("Project"))),
    note(
      sprintf(tr("Project: %s"), summary$title),
      if (summary$dirty) htmltools::tags$span(
        class = "text-warning", paste0(" \u00b7 ", tr("unsaved changes"))
      )
    ),
    note(if (is.null(summary$path)) tr("Not saved yet") else summary$path),
    action_row(
      actionButton("home_project_new", tr("New project"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("home_project_open", tr("Open project"),
                   class = "btn-sm btn-outline-secondary"),
      actionButton("home_project_save", tr("Save project"),
                   class = "btn-sm btn-outline-primary"),
      actionButton("home_project_bundle", tr("Export bundle"),
                   class = "btn-sm btn-outline-secondary")
    ),
    if (length(recent_choices) > 0L) {
      htmltools::tagList(
        selectInput("home_project_recent", tr("Recent projects"),
                    choices = c(stats::setNames("", tr("Choose a recent project")), recent_choices), width = "100%"),
        actionButton("home_project_recent_open", tr("Open selected"),
                     class = "btn-sm btn-outline-secondary")
      )
    }
  )
}
