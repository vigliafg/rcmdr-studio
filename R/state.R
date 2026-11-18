# Application state ---------------------------------------------------------
#
# The state is a plain environment so that it can be created and inspected
# without a running Shiny session (useful for tests).  A single state belongs
# to a single session: the package targets a local, single-user deployment and
# therefore keeps Rcmdr's .GlobalEnv semantics.

#' Create an application state
#'
#' @param env Evaluation environment used by [run_command()].  Defaults to the
#'   global environment, mirroring Rcmdr.
#' @return An environment of class `RcmdrShinyState`.
#' @export
AppState <- function(env = globalenv()) {
  state <- new.env(parent = emptyenv())
  class(state) <- "RcmdrShinyState"

  state$env <- env
  state$active_dataset <- NULL
  state$active_model <- NULL
  state$model_selection <- NULL
  state$environment_selection <- NULL
  state$environment_preview <- NULL

  # Data Studio: dataset registry, data dictionary, session checkpoints and
  # the current grid selection.  `state$active_dataset` remains the single
  # source of truth used by the rest of the engine.
  state$datasets <- list()
  state$data_dictionary <- list()
  state$checkpoints <- list()
  state$checkpoint_counter <- 0L
  state$data_selection <- NULL
  state$data_grid_revision <- 0L
  state$last_checkpoint_skip <- NULL

  state$log <- character()
  state$output <- character()
  state$output_stack <- list()
  .output_stack$values <- list()
  state$messages <- character()
  state$warnings <- character()
  state$last_error <- NULL

  # Structured history.  It runs beside the command log: the log remains the
  # compatibility contract, while the history records enough metadata to rerun,
  # reopen a dialog or insert a step into the script/report.
  state$history <- list()
  state$history_counter <- 0L
  state$recent_commands <- character()
  state$history_pinned <- character()
  state$console_history <- character()
  state$console_index <- 0L
  state$console_last <- NULL
  # Messages are kept twice: `state$messages` is the historical text buffer,
  # `state$message_entries` is the structured list used by the Messages tab.
  state$message_entries <- list()
  state$message_counter <- 0L

  # The source of the command currently being executed.  It is consumed by
  # run_command() and reset by the caller.
  state$execution_source <- NULL
  state$execution_id <- NULL

  state$dialog_memory <- list()
  state$dialog_presets <- list()
  state$dialog_presets_version <- 1L
  # Inline field errors returned by a dialog `on_ok` callback as
  # `field_errors`; the runtime renders them under the fields.
  state$dialog_errors <- list()

  # Navigation: favourites, recents and the persisted expansion of the menu
  # tree.  They are session preferences, never commands.
  state$menu_favorites <- character()
  state$menu_recents <- character()
  state$menu_expanded <- character()

  # Guided workflows: the active instance plus its counter.  A workflow only
  # orchestrates the existing dialogs and commands.
  state$workflow <- NULL
  state$workflow_counter <- 0L
  state$workflow_history <- list()

  # Cache for the palette index.  It is rebuilt when the state revision or the
  # plugin registry changes.
  state$palette_cache <- NULL
  state$palette_cache_key <- NULL

  # Document authoring: the Script tab can hold a plain script or an R
  # Markdown/knitr document.  The path, mode and text live here so dialogs and
  # direct commands share the same buffer.
  state$document <- list(text = "", path = NULL, mode = "r")
  # Report Studio: the document registry.  `state$document` remains the
  # active buffer for backward compatibility; every registry entry is kept in
  # sync with it.
  state$documents <- list()
  state$active_document <- NULL
  state$document_counter <- 0L
  state$document_dirty <- FALSE
  state$autosave_dir <- NULL
  state$autosave_time <- NULL
  state$recoveries <- list()
  # Executable cells: chunk id -> captured output.  Session state, not document
  # content; the knit always re-executes the chunks.
  state$cell_outputs <- list()
  state$cell_counter <- 0L
  # Workbench: inline output of the Script cells.  The keys are cell ids and
  # the map is cleared whenever the script text changes, because the ids are
  # positional.
  state$script_outputs <- list()
  state$knit_result <- NULL
  state$knit_history <- list()
  state$knit_counter <- 0L
  # Set by the Shiny server so direct commands can refresh the editor.
  state$sync_document <- NULL
  state$open_dialog <- NULL
  state$plots <- list()
  state$plot_counter <- 0L
  # Chart Studio: the last applied chart specification, the active chart
  # selection and the gallery filter state.  Plots themselves stay in
  # `state$plots`, which the report already consumes.
  state$chart_last_spec <- NULL
  state$chart_selection <- NULL
  state$rgl_scene <- NULL
  state$rgl_widget <- NULL
  state$current_dialog <- NULL
  state$last_failed_dialog <- NULL

  state$model_number <- 0L
  state$revision <- 0L
  state$busy <- FALSE

  # Project persistence (Wave 7).  `project_path` is the saved file, while
  # `project_title` is the display name.  The dirty flag is set by mutations
  # that change the project payload; autosave and recovery use the separate
  # `.autosave` file beside the project.
  state$project_path <- NULL
  state$project_title <- NULL
  state$project_created <- NULL
  state$project_modified <- NULL
  state$project_dirty <- FALSE
  state$project_autosave_time <- NULL
  state$project_recent_file <- NULL
  state$project_models <- list()
  state$session_checkpoints <- list()
  state$session_checkpoint_counter <- 0L

  state$session <- NULL
  state$session_started <- Sys.time()
  state$set_script <- NULL
  state$plot_dir <- NULL
  state$plot_prefix <- NULL
  # Where the last dialog command put its result, so the interface can point at
  # the right window instead of leaving the result to be found.
  state$last_result <- NULL
  state$options <- list(
    digits = 7L,
    width = 80L,
    stringsAsFactors = TRUE,
    edit_threshold = 10000L,
    max_output_lines = 20000L,
    max_plots = 50L,
    output_stack_length = 10L,
    dt_server_threshold = 5000L,
    chart_preview_width = 640L,
    chart_preview_height = 420L,
    chart_preview_cache = 12L,
    report_preview_cache = 8L,
    autosave_interval = 30000L,
    document_backup = TRUE,
    console_history_length = 100L,
    script_cells = TRUE,
    script_format = TRUE,
    checkpoint_max = 20L,
    checkpoint_max_bytes = 50 * 1024^2,
    session_checkpoint_max = 10L,
    import_preview_rows = 20L,
    use_markdown = FALSE,
    use_knitr = FALSE,
    language = current_language(),
    theme = "system",
    density = "compact",
    ui_mode = "studio",
    history_length = 200L,
    menu_recent_length = 8L,
    persist_preferences = TRUE,
    preferences_file = NULL,
    auto_switch_result = FALSE,
    project_recent_length = 8L,
    project_history = FALSE,
    project_autosave = TRUE,
    script_output_cells = 50L,
    knit_history_length = 20L,
    plugin_lazy = FALSE,
    workflow_step_limit = 50L,
    layouts = list(),
    column_order = list(),
    workspace_secondary = NULL,
    features = default_features(),
    capabilities = rcmdr_capabilities()
  )

  # Called after every mutation that the UI should react to.  The Shiny server
  # replaces it with a function that bumps a reactive counter.
  state$notify <- function() invisible(NULL)

  state
}

is_app_state <- function(state) inherits(state, "RcmdrShinyState")

#' @keywords internal
state_touch <- function(state) {
  if (!is_app_state(state)) return(invisible(NULL))
  state$revision <- state$revision + 1L
  # Any session mutation makes an open project dirty.  Project save/load
  # clears the flag after calling state_touch().
  if (!is.null(state$project_path)) state$project_dirty <- TRUE
  notify <- state$notify
  if (is.function(notify)) notify()
  invisible(state$revision)
}

#' Active data set
#'
#' `active_dataset()` gets or sets the name of the active data set.
#' @param state Application state.
#' @param value Name of an object in `state$env` holding a data frame.  Use
#'   `NULL` to clear the active data set.
#' @export
active_dataset <- function(state, value) {
  if (missing(value)) return(state$active_dataset)

  if (is.null(value)) {
    state$active_dataset <- NULL
    state$active_model <- NULL
    state_touch(state)
    return(invisible(NULL))
  }

  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    stop("The active data set must be a single object name.", call. = FALSE)
  }
  if (!exists(value, envir = state$env, inherits = FALSE)) {
    stop(sprintf("Object '%s' does not exist.", value), call. = FALSE)
  }
  object <- get(value, envir = state$env, inherits = FALSE)
  if (!is.data.frame(object)) {
    stop(sprintf("Object '%s' is not a data frame.", value), call. = FALSE)
  }

  if (!identical(state$active_dataset, value)) {
    state$active_model <- NULL
  }
  state$active_dataset <- value
  if (is.function(dataset_register)) dataset_register(state, value)
  state_touch(state)
  invisible(value)
}

#' @keywords internal
dataset <- function(state) {
  name <- state$active_dataset
  if (is.null(name) || !exists(name, envir = state$env, inherits = FALSE)) {
    return(NULL)
  }
  object <- get(name, envir = state$env, inherits = FALSE)
  if (!is.data.frame(object)) NULL else object
}

#' Number of cells in the active data set
#' @keywords internal
dataset_cells <- function(state) {
  df <- dataset(state)
  if (is.null(df)) 0L else as.integer(nrow(df)) * as.integer(ncol(df))
}

#' Whether the active data set can be edited in the browser
#' @keywords internal
editable_dataset <- function(state) {
  !is.null(dataset(state)) &&
    dataset_cells(state) <= (state$options$edit_threshold %||% 0L)
}

#' Replace the active data set with an edited version
#' @keywords internal
update_dataset <- function(state, df) {
  name <- active_dataset(state)
  if (is.null(name)) stop("There is no active data set.", call. = FALSE)
  if (!is.data.frame(df)) stop("The edited object is not a data frame.", call. = FALSE)
  assign(name, df, envir = state$env)
  if (is.function(dataset_register)) dataset_register(state, name)
  state_touch(state)
  invisible(df)
}

#' @keywords internal
variables <- function(state) {
  df <- dataset(state)
  if (is.null(df)) character() else names(df)
}

#' @keywords internal
numeric_variables <- function(state) {
  df <- dataset(state)
  if (is.null(df)) return(character())
  names(df)[vapply(df, is.numeric, logical(1))]
}

#' @keywords internal
factor_variables <- function(state) {
  df <- dataset(state)
  if (is.null(df)) return(character())
  names(df)[vapply(df, function(x) is.factor(x) || is.logical(x) || is.character(x), logical(1))]
}

#' @keywords internal
two_level_factors <- function(state) {
  df <- dataset(state)
  if (is.null(df)) return(character())
  vars <- factor_variables(state)
  vars[vapply(vars, function(v) {
    x <- df[[v]]
    if (is.character(x)) x <- factor(x)
    nlevels(x) == 2L
  }, logical(1))]
}

# Rcmdr's discreteness threshold (see listDiscreteNumeric in Rcmdr).
discreteness_threshold <- function(n) {
  if (!is.finite(n) || n < 1) return(100L)
  min(round(2 * sqrt(n)), round(10 * log10(n)), 100L)
}

#' @keywords internal
discrete_numeric_variables <- function(state) {
  df <- dataset(state)
  if (is.null(df)) return(character())
  vars <- numeric_variables(state)
  if (length(vars) == 0L) return(character())
  threshold <- discreteness_threshold(nrow(df))
  vars[vapply(vars, function(v) length(unique(df[[v]])) <= threshold, logical(1))]
}

#' Active model
#'
#' @param state Application state.
#' @param value Name of an object in `state$env`, or `NULL`.
#' @export
active_model <- function(state, value) {
  if (missing(value)) return(state$active_model)
  if (!is.null(value)) {
    if (!is.character(value) || length(value) != 1L || is.na(value)) {
      stop("The active model must be a single object name.", call. = FALSE)
    }
    if (!exists(value, envir = state$env, inherits = FALSE)) {
      stop(sprintf("Object '%s' does not exist.", value), call. = FALSE)
    }
  }
  state$active_model <- value
  state_touch(state)
  invisible(value)
}

#' @keywords internal
update_model_number <- function(state, increment = 1L) {
  state$model_number <- max(1L, as.integer(state$model_number + increment))
  invisible(state$model_number)
}

#' Dialog memory
#' @keywords internal
get_dialog_memory <- function(state, id) {
  state$dialog_memory[[id]]
}

#' @keywords internal
set_dialog_memory <- function(state, id, values) {
  if (isTRUE(getOption("RcmdrShiny.strict_memory", FALSE)) &&
      is.list(values) && length(values) > 0L) {
    unknown <- tryCatch(dialog_memory_unknown_keys(id, values, state),
                        error = function(e) character())
    if (length(unknown) > 0L) {
      warning(sprintf(
        "Dialog '%s' received unknown memory keys: %s",
        id, paste(unknown, collapse = ", ")
      ), call. = FALSE)
    }
  }
  state$dialog_memory[[id]] <- values
  invisible(values)
}

#' @keywords internal
clear_dialog_memory <- function(state, id) {
  state$dialog_memory[[id]] <- NULL
  invisible(NULL)
}

# Small utilities -----------------------------------------------------------

`%||%` <- function(x, y) {
  if (is.null(x) || (length(x) == 1L && is.na(x))) y else x
}

trim_blanks <- function(x) {
  if (is.null(x)) return("")
  gsub("^[[:space:]]+|[[:space:]]+$", "", x)
}

#' @keywords internal
is_valid_name <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name) || !nzchar(name)) {
    return(FALSE)
  }
  if (!identical(make.names(name), name)) return(FALSE)
  !name %in% c(
    "if", "else", "repeat", "while", "function", "for", "next", "break",
    "TRUE", "FALSE", "NULL", "Inf", "NaN", "NA", "NA_integer_",
    "NA_real_", "NA_character_", "in"
  )
}

#' Attach packages needed by Rcmdr-generated commands
#' @keywords internal
attach_packages <- function(packages) {
  for (package in packages) {
    if (!package %in% .packages()) {
      suppressPackageStartupMessages(
        library(package, character.only = TRUE, quietly = TRUE,
                warn.conflicts = FALSE)
      )
    }
  }
  invisible(NULL)
}

quote_string <- function(x) paste0('"', x, '"')

quote_vars <- function(x) {
  if (length(x) == 1L) {
    quote_string(x)
  } else {
    paste0("c(", paste0(quote_string(x), collapse = ", "), ")")
  }
}
