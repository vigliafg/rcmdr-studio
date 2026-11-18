# Project schema -------------------------------------------------------------
#
# A project is a versioned, portable description of a working session.  It is
# deliberately a plain list so that it can be inspected, validated and
# serialised without a running Shiny session.  The statistical work still lives
# in the evaluation environment: a project stores the data set paths, the
# registry metadata, the documents, the plots and the user preferences.
#
# P7.1 defines the schema, the entry constructors, the validator, the migration
# entry point and the path helpers.  File reading and writing (P7.2) build on
# these functions and must not duplicate them.

#' Current project schema version
#' @return An integer scalar.
#' @keywords internal
project_schema_version <- function() 1L

#' Project file extension
#' @return A string without the leading dot.
#' @keywords internal
project_extension <- function() "rcmdrproj"

#' ISO-8601 timestamp used by the project schema
#' @param time A `POSIXt` scalar.
#' @return A UTC timestamp such as `2026-11-14T10:00:00Z`.
#' @keywords internal
project_timestamp <- function(time = Sys.time()) {
  format(time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Version of the running package, for the project header
#' @keywords internal
project_package_version <- function() {
  tryCatch(
    as.character(utils::packageVersion("RcmdrShiny")),
    error = function(e) "0.0.0"
  )
}

# -- type predicates ---------------------------------------------------------

project_is_string <- function(x, allow_empty = TRUE) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) return(FALSE)
  if (isTRUE(allow_empty)) TRUE else nzchar(x)
}

project_is_flag <- function(x) {
  is.logical(x) && length(x) == 1L && !is.na(x)
}

project_is_number <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
}

project_is_timestamp <- function(x) {
  if (!project_is_string(x, allow_empty = FALSE)) return(FALSE)
  grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(Z|[+-]\\d{2}:\\d{2})$",
        x, perl = TRUE)
}

# -- entry constructors ------------------------------------------------------

#' Describe a data set in a project
#'
#' @param name Object name the data set has in the evaluation environment.
#' @param source Path to the data file, relative to the project when possible.
#' @param include Whether the file is copied into the project bundle.
#' @param active Whether this is the active data set.
#' @param dictionary Named list of variable labels, units and descriptions.
#' @return A project entry.
#' @keywords internal
project_dataset <- function(name, source = NULL, include = FALSE,
                            active = FALSE, dictionary = list()) {
  list(
    name = as.character(name),
    source = if (is.null(source)) NULL else as.character(source),
    include = isTRUE(include),
    active = isTRUE(active),
    dictionary = dictionary %||% list()
  )
}

#' Describe a fitted model in a project
#' @keywords internal
project_model_entry <- function(name, class, formula = NULL, data = NULL) {
  list(
    name = as.character(name),
    class = as.character(class),
    formula = if (is.null(formula)) NULL else as.character(formula),
    data = if (is.null(data)) NULL else as.character(data)
  )
}

#' Describe a document in a project
#' @keywords internal
project_document_entry <- function(id, path = NULL, mode = "r", text = "",
                                   active = FALSE) {
  list(
    id = as.character(id),
    path = if (is.null(path)) NULL else as.character(path),
    mode = as.character(mode),
    text = paste(as.character(text %||% ""), collapse = "\n"),
    active = isTRUE(active)
  )
}

#' Describe a plot in a project
#' @keywords internal
project_plot_entry <- function(id, file = NULL, title = NULL, spec = NULL,
                               pinned = FALSE, order = NULL) {
  list(
    id = as.character(id),
    file = if (is.null(file)) NULL else as.character(file),
    title = if (is.null(title)) NULL else as.character(title),
    spec = spec %||% NULL,
    pinned = isTRUE(pinned),
    order = if (is.null(order)) NULL else as.numeric(order)
  )
}

#' Project-level user options
#' @keywords internal
project_options <- function(ui_mode = "studio", theme = "system",
                            language = current_language()) {
  list(
    ui_mode = as.character(ui_mode),
    theme = as.character(theme),
    language = as.character(language)
  )
}

# -- schema ------------------------------------------------------------------

#' Create an empty project
#'
#' The result is valid according to [project_validate()]; it contains no data
#' set, model, document or plot.  `path` is runtime metadata and is not part of
#' the serialised payload.
#'
#' @param path Optional project file path.
#' @param title Optional human-readable title.
#' @return A project list.
#' @keywords internal
project_new <- function(path = NULL, title = NULL) {
  now <- project_timestamp()
  list(
    version = project_schema_version(),
    created = now,
    modified = now,
    package_version = project_package_version(),
    title = title %||% "",
    datasets = list(),
    models = list(),
    active_model = NULL,
    documents = list(),
    active_document = NULL,
    plots = list(),
    presets = list(),
    favorites = character(),
    options = project_options(),
    history = list(include = FALSE),
    path = if (is.null(path)) NULL else as.character(path)
  )
}

#' Keys that belong to the runtime object, not to the file
#' @keywords internal
project_payload <- function(project) {
  if (!is.list(project)) return(project)
  project[setdiff(names(project), "path")]
}

# -- persistence -------------------------------------------------------------

#' Project file name from a title
#' @keywords internal
project_file_name <- function(title = NULL) {
  title <- trimws(as.character(title %||% ""))
  if (!nzchar(title)) title <- "project"
  title <- gsub("[^A-Za-z0-9._ -]+", "-", title)
  title <- gsub("[[:space:]]+", "-", title)
  paste0(title, ".", project_extension())
}

#' Sanitise a data set name for a file inside the project
#' @keywords internal
project_safe_name <- function(name) {
  name <- gsub("[^A-Za-z0-9._-]+", "_", as.character(name %||% ""))
  name <- gsub("^[._-]+|[._-]+$", "", name)
  if (!nzchar(name)) "dataset" else name
}

#' Serialise a project to YAML
#' @keywords internal
project_to_yaml <- function(project) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("The 'yaml' package is required to save a project.", call. = FALSE)
  }
  yaml::as.yaml(project_payload(project))
}

#' Parse a project from YAML
#' @keywords internal
project_from_yaml <- function(text) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("The 'yaml' package is required to open a project.", call. = FALSE)
  }
  value <- tryCatch(
    yaml::yaml.load(paste(text, collapse = "\n"), eval.expr = FALSE),
    error = function(e) {
      stop(sprintf("The project file is not valid YAML: %s",
                   conditionMessage(e)), call. = FALSE)
    }
  )
  if (!is.list(value)) {
    stop("The project file does not contain a project object.", call. = FALSE)
  }
  value
}

#' Write a project atomically
#'
#' @param project Project list.
#' @param path Destination file.
#' @keywords internal
project_write_file <- function(project, path) {
  text <- project_to_yaml(project)
  directory <- dirname(path)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("rcmdr-project-", tmpdir = directory)
  on.exit(unlink(temporary), add = TRUE)
  writeLines(text, temporary, useBytes = TRUE)
  if (file.exists(path)) {
    backup <- paste0(path, ".bak")
    try(file.copy(path, backup, overwrite = TRUE), silent = TRUE)
  }
  if (!file.rename(temporary, path)) {
    unlink(path)
    if (!file.rename(temporary, path)) {
      stop(sprintf("Could not write the project file: %s", path),
           call. = FALSE)
    }
  }
  invisible(path)
}

#' Read a project from disk
#'
#' @param path Project file.
#' @return A migrated, validated project.
#' @keywords internal
project_read <- function(path) {
  if (!project_is_string(path, allow_empty = FALSE) ||
      !file.exists(path)) {
    stop(sprintf("Project file not found: %s", as.character(path)),
         call. = FALSE)
  }
  text <- readLines(path, warn = FALSE, encoding = "UTF-8")
  project <- project_from_yaml(text)
  project <- project_migrate(project)
  project_validate_or_stop(project)
  project$path <- project_normalize_path(path.expand(path))
  project
}

#' Open a project
#'
#' Alias of [project_read()] kept as the public task name from the plan.
#' @keywords internal
project_open <- function(path) project_read(path)

#' Write a project payload and its referenced files
#'
#' Internal workhorse shared by save, autosave and bundle export.  It never
#' changes the session metadata.
#'
#' @param state Application state.
#' @param path Destination project file.
#' @param include_history Whether to include the command history.
#' @return The written project, invisibly.
#' @keywords internal
project_write <- function(state, path, include_history = NULL) {
  path <- project_normalize_path(path.expand(path))
  project <- project_build(state, path, include_history = include_history)
  directory <- dirname(path)

  # Included data sets are written next to the project.
  for (i in seq_along(project$datasets)) {
    entry <- project$datasets[[i]]
    if (!isTRUE(entry$include)) next
    data <- get0(entry$name, envir = state$env, inherits = FALSE)
    if (!is.data.frame(data)) next
    destination <- file.path(directory, entry$source)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(data, destination, row.names = FALSE, na = "")
    project$datasets[[i]]$source <- entry$source
  }

  # Plots are copied into assets/ under their stable id.
  sources <- attr(project, "plot_sources") %||% character()
  for (i in seq_along(project$plots)) {
    entry <- project$plots[[i]]
    source <- sources[[entry$id]] %||% ""
    destination <- file.path(directory, entry$file %||% "")
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    if (nzchar(source) && file.exists(source)) {
      try(file.copy(source, destination, overwrite = TRUE), silent = TRUE)
    }
    project$plots[[i]]$file <- entry$file
  }
  attr(project, "plot_sources") <- NULL

  project_write_file(project, path)
  invisible(project)
}

#' Build the project payload from the session
#'
#' @param state Application state.
#' @param path Destination path, used to relativise sources.
#' @param include_history Whether to include the command history.
#' @keywords internal
project_build <- function(state, path = NULL,
                          include_history = NULL) {
  root <- if (is.null(path)) NULL else dirname(path)
  project <- project_new(path = path)
  project$title <- state$project_title %||% ""
  project$created <- state$project_created %||% project$created
  project$modified <- project_timestamp()

  registry <- tryCatch(dataset_registry(state), error = function(e) NULL)
  dataset_names <- if (!is.null(registry) && nrow(registry) > 0L) {
    registry$name
  } else {
    names(state$datasets %||% list())
  }
  datasets <- list()
  for (name in dataset_names) {
    data <- get0(name, envir = state$env, inherits = FALSE)
    if (!is.data.frame(data)) next
    meta <- (state$datasets %||% list())[[name]] %||% list()
    source <- meta$source %||% ""
    include <- FALSE
    if (!nzchar(source) || !file.exists(source) ||
        identical(source, "session") || identical(source, "command")) {
      source <- file.path("data", paste0(project_safe_name(name), ".csv"))
      include <- TRUE
    } else if (!is.null(root)) {
      source <- project_relative_path(source, root)
    }
    datasets[[length(datasets) + 1L]] <- project_dataset(
      name = name,
      source = source,
      include = include,
      active = identical(name, state$active_dataset),
      dictionary = (state$data_dictionary %||% list())[[name]] %||% list()
    )
  }
  project$datasets <- datasets

  models <- tryCatch(model_registry(state), error = function(e) NULL)
  entries <- list()
  if (!is.null(models) && nrow(models) > 0L) {
    for (i in seq_len(nrow(models))) {
      row <- models[i, , drop = FALSE]
      entries[[length(entries) + 1L]] <- project_model_entry(
        row$name[[1L]], row$class[[1L]],
        formula = row$formula[[1L]] %||% NULL,
        data = row$data[[1L]] %||% NULL
      )
    }
  }
  project$models <- entries
  project$active_model <- state$active_model

  documents <- list()
  source_documents <- state$documents %||% list()
  if (length(source_documents) == 0L &&
      nzchar(document_text(state) %||% "")) {
    source_documents <- list(list(
      id = "document-0001",
      title = "Untitled document",
      path = document_path(state),
      mode = document_mode(state),
      text = document_text(state)
    ))
  }
  for (document in source_documents) {
    doc_path <- document$path %||% NULL
    if (!is.null(doc_path) && nzchar(doc_path) && !is.null(root)) {
      doc_path <- project_relative_path(doc_path, root)
    }
    documents[[length(documents) + 1L]] <- project_document_entry(
      id = document$id %||% sprintf("document-%04d", length(documents) + 1L),
      path = doc_path,
      mode = document$mode %||% "r",
      text = document$text %||% "",
      active = identical(document$id, state$active_document)
    )
  }
  project$documents <- documents
  project$active_document <- state$active_document

  plots <- list()
  plot_sources <- character()
  for (plot in state$plots %||% list()) {
    id <- plot$id %||% sprintf("plot-%04d", length(plots) + 1L)
    file <- plot$file %||% ""
    extension <- if (nzchar(file)) tools::file_ext(file) else "png"
    if (!nzchar(extension)) extension <- "png"
    plot_sources[[id]] <- file
    plots[[length(plots) + 1L]] <- project_plot_entry(
      id = id,
      file = file.path("assets", paste0(project_safe_name(id), ".", extension)),
      title = plot$title %||% NULL,
      spec = plot$spec %||% NULL,
      pinned = isTRUE(plot$pinned),
      order = plot$order %||% (length(plots) + 1L)
    )
  }
  project$plots <- plots
  attr(project, "plot_sources") <- plot_sources

  project$presets <- state$dialog_presets %||% list()
  project$favorites <- state$menu_favorites %||% character()
  project$options <- project_options(
    ui_mode = ui_mode(state),
    theme = state$options$theme %||% "system",
    language = state$options$language %||% current_language()
  )
  include <- include_history %||% isTRUE(state$options$project_history)
  project$history <- list(include = isTRUE(include))
  if (isTRUE(include)) {
    project$history$entries <- lapply(state$history %||% list(), function(entry) {
      list(
        time = format(entry$time %||% Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        source = entry$source %||% "script",
        command = entry$command %||% "",
        dialog_id = entry$dialog_id %||% NULL
      )
    })
  }

  project
}

#' Save the session to a project file
#'
#' @param state Application state.
#' @param path Destination.  Defaults to the current project path.
#' @param include_history Include the structured command history.
#' @return The project path, invisibly.
#' @keywords internal
project_save <- function(state, path = NULL, include_history = NULL) {
  path <- path %||% state$project_path
  if (!project_is_string(path, allow_empty = FALSE)) {
    stop("Choose a project file first.", call. = FALSE)
  }
  path <- project_normalize_path(path.expand(path))
  if (!grepl(paste0("\\.", project_extension(), "$"), path,
             ignore.case = TRUE)) {
    path <- paste0(path, ".", project_extension())
  }
  if (is.null(state$project_title) || !nzchar(state$project_title)) {
    state$project_title <- sub(paste0("\\.", project_extension(), "$"), "",
                               basename(path))
  }
  project <- project_write(state, path, include_history = include_history)

  state$project_path <- path
  state$project_title <- project$title %||% basename(path)
  state$project_created <- project$created
  state$project_modified <- project$modified
  state$project_models <- project$models
  state$project_autosave_time <- NULL
  project_remove_autosave(state)
  project_recent_add(path, state$project_title,
                     file = state$project_recent_file)
  state_touch(state)
  state$project_dirty <- FALSE
  invisible(path)
}

#' Save a project under a new path
#' @keywords internal
project_save_as <- function(state, path, include_history = NULL) {
  state$project_title <- sub(paste0("\\.", project_extension(), "$"), "",
                             basename(path))
  project_save(state, path = path, include_history = include_history)
}

#' Read a data file referenced by a project
#' @keywords internal
project_read_dataset <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Data file not found: %s", path), call. = FALSE)
  }
  extension <- tolower(tools::file_ext(path))
  data <- switch(
    extension,
    csv = utils::read.csv(path, stringsAsFactors = TRUE, check.names = FALSE),
    tsv = utils::read.delim(path, stringsAsFactors = TRUE, check.names = FALSE),
    txt = utils::read.table(path, header = TRUE, stringsAsFactors = TRUE),
    rds = readRDS(path),
    rda = ,
    rdata = {
      environment <- new.env(parent = emptyenv())
      loaded <- load(path, envir = environment)
      frames <- Filter(function(name) {
        is.data.frame(get(name, envir = environment, inherits = FALSE))
      }, loaded)
      if (length(frames) == 0L) {
        stop(sprintf("No data frame in %s.", path), call. = FALSE)
      }
      get(frames[[1L]], envir = environment, inherits = FALSE)
    },
    stop(sprintf("Unsupported data format: .%s", extension), call. = FALSE)
  )
  if (!is.data.frame(data)) {
    stop(sprintf("The file does not contain a data frame: %s", path),
         call. = FALSE)
  }
  data
}

#' Apply a project to a session
#'
#' Restores data sets, documents, plots, presets, favourites and options.  The
#' statistical objects that the project only describes (models) must still
#' exist in the evaluation environment; their active selection is restored when
#' they do.
#'
#' @param state Application state.
#' @param project A validated project.
#' @param path Project path, used to resolve relative files.
#' @return The project, invisibly.
#' @keywords internal
project_apply <- function(state, project, path = NULL) {
  project <- project_migrate(project)
  project_validate_or_stop(project)
  path <- path %||% project$path %||% state$project_path
  root <- if (is.null(path)) getwd() else dirname(path)
  warnings <- character()

  for (entry in project$datasets) {
    source <- project_resolve_path(entry$source, root)
    data <- tryCatch(project_read_dataset(source), error = function(e) e)
    if (inherits(data, "error")) {
      warnings <- c(warnings, conditionMessage(data))
      next
    }
    assign(entry$name, data, envir = state$env)
    dataset_register(state, entry$name, source = source, refresh = TRUE)
    dictionary <- entry$dictionary %||% list()
    if (length(dictionary) > 0L) {
      state$data_dictionary[[entry$name]] <- dictionary
      for (variable in names(dictionary)) {
        if (!variable %in% names(data)) next
        info <- dictionary[[variable]]
        column <- data[[variable]]
        for (field in c("label", "units", "description")) {
          if (!is.null(info[[field]])) attr(column, field) <- info[[field]]
        }
        data[[variable]] <- column
      }
      assign(entry$name, data, envir = state$env)
    }
    if (isTRUE(entry$active)) state$active_dataset <- entry$name
  }
  if (is.null(state$active_dataset) && length(project$datasets) > 0L) {
    first <- project$datasets[[1L]]$name %||% NULL
    if (!is.null(first) && exists(first, envir = state$env, inherits = FALSE)) {
      state$active_dataset <- first
    }
  }
  if (!is.null(state$active_dataset) &&
      !exists(state$active_dataset, envir = state$env, inherits = FALSE)) {
    state$active_dataset <- NULL
  }

  state$project_models <- project$models
  if (!is.null(project$active_model) &&
      exists(project$active_model, envir = state$env, inherits = FALSE)) {
    state$active_model <- project$active_model
  } else {
    state$active_model <- NULL
  }

  state$documents <- list()
  document_counter <- 0L
  for (entry in project$documents) {
    id <- entry$id
    document <- list(
      id = id,
      title = if (!is.null(entry$path) && nzchar(entry$path)) {
        basename(entry$path)
      } else {
        tr("Untitled document")
      },
      path = if (!is.null(entry$path)) {
        project_resolve_path(entry$path, root)
      } else {
        NULL
      },
      mode = entry$mode %||% "r",
      text = paste(entry$text %||% "", collapse = "\n"),
      dirty = FALSE,
      last_saved = Sys.time(),
      autosave_path = NULL,
      autosave_time = NULL
    )
    state$documents[[id]] <- document
    suffix <- suppressWarnings(as.integer(sub("^.*-", "", id)))
    if (!is.na(suffix)) document_counter <- max(document_counter, suffix)
  }
  state$document_counter <- document_counter
  state$active_document <- project$active_document
  if (is.null(state$active_document) && length(state$documents) > 0L) {
    state$active_document <- names(state$documents)[[1L]]
  }
  if (!is.null(state$active_document) &&
      !state$active_document %in% names(state$documents)) {
    state$active_document <- if (length(state$documents) > 0L) {
      names(state$documents)[[1L]]
    } else {
      NULL
    }
  }
  if (!is.null(state$active_document)) {
    state$document <- state$documents[[state$active_document]]
    document_enable_options(state, state$document$mode %||% "r")
  } else {
    state$document <- list(text = "", path = NULL, mode = "r",
                           title = tr("Untitled document"), dirty = FALSE)
  }

  state$plots <- list()
  plot_counter <- 0L
  for (entry in project$plots) {
    index <- length(state$plots) + 1L
    file <- if (!is.null(entry$file)) {
      project_resolve_path(entry$file, root)
    } else {
      NULL
    }
    state$plots[[index]] <- list(
      id = entry$id,
      index = index,
      file = file,
      url = NULL,
      code = NULL,
      recorded = NULL,
      time = Sys.time(),
      spec = entry$spec %||% NULL,
      title = entry$title %||% NULL,
      tags = character(),
      pinned = isTRUE(entry$pinned),
      order = entry$order %||% index,
      interactive_code = NULL
    )
    suffix <- suppressWarnings(as.integer(sub("^.*-", "", entry$id)))
    if (!is.na(suffix)) plot_counter <- max(plot_counter, suffix)
  }
  state$plot_counter <- plot_counter

  state$dialog_presets <- project$presets %||% list()
  state$menu_favorites <- project$favorites %||% character()
  options <- project$options %||% list()
  if (!is.null(options$ui_mode)) state$options$ui_mode <- options$ui_mode
  if (!is.null(options$theme)) state$options$theme <- options$theme
  if (!is.null(options$language)) {
    state$options$language <- options$language
    try(i18n_set_language(options$language), silent = TRUE)
  }

  if (isTRUE(project$history$include) &&
      length(project$history$entries %||% list()) > 0L) {
    entries <- lapply(project$history$entries, function(entry) {
      list(
        id = history_next_id(state),
        time = tryCatch(
          as.POSIXct(entry$time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
          error = function(e) Sys.time()
        ),
        source = entry$source %||% "script",
        command = entry$command %||% "",
        dialog_id = entry$dialog_id %||% NULL,
        dialog_memory = NULL,
        status = "ok",
        output = character(),
        messages = character(),
        warnings = character(),
        error = NULL,
        plot_id = NULL,
        duration_ms = NA_real_
      )
    })
    state$history <- c(entries, state$history %||% list())
    state$history <- utils::head(state$history,
                                 as.integer(state$options$history_length %||%
                                              200L))
  }

  state$project_path <- if (!is.null(path)) {
    project_normalize_path(path.expand(path))
  } else {
    NULL
  }
  state$project_title <- project$title %||%
    basename(state$project_path %||% "project")
  state$project_created <- project$created
  state$project_modified <- project$modified
  state$project_autosave_time <- NULL
  state$project_last_error <- if (length(warnings) > 0L) {
    paste(unique(warnings), collapse = "\n")
  } else {
    NULL
  }
  if (!is.null(state$project_path)) {
    project_recent_add(state$project_path, state$project_title,
                       file = state$project_recent_file)
  }
  state_touch(state)
  state$project_dirty <- FALSE
  invisible(project)
}

#' Open a project into a session
#' @keywords internal
project_load <- function(state, path) {
  project <- project_read(path)
  project_apply(state, project, path = project$path %||% path)
  invisible(project)
}

# -- recent projects ---------------------------------------------------------

#' File that stores the recent project list
#' @keywords internal
project_recent_file <- function(path = NULL) {
  if (!is.null(path) && nzchar(path)) return(path)
  override <- Sys.getenv("RCMDRSHINY_PROJECTS", unset = "")
  if (nzchar(override)) return(override)
  override <- getOption("RcmdrShiny.projects")
  if (!is.null(override) && nzchar(override)) return(override)
  file.path(dirname(preferences_default_file()), "projects.rds")
}

#' Recent projects
#'
#' @param limit Maximum number of entries.
#' @param path Optional override of the recent-projects file.
#' @return A data frame with `path`, `title`, `modified` and `exists`.
#' @keywords internal
project_recent <- function(limit = 8L, path = NULL, file = NULL) {
  file <- project_recent_file(file %||% path)
  entries <- if (file.exists(file)) {
    tryCatch(readRDS(file), error = function(e) list())
  } else {
    list()
  }
  if (!is.list(entries) || length(entries) == 0L) {
    return(data.frame(path = character(), title = character(),
                      modified = character(), exists = logical(),
                      stringsAsFactors = FALSE))
  }
  rows <- lapply(entries, function(entry) {
    entry_path <- as.character(entry$path %||% "")
    if (!nzchar(entry_path)) return(NULL)
    data.frame(
      path = entry_path,
      title = as.character(entry$title %||% basename(entry_path)),
      modified = as.character(entry$modified %||% ""),
      exists = file.exists(entry_path),
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(data.frame(path = character(), title = character(),
                      modified = character(), exists = logical(),
                      stringsAsFactors = FALSE))
  }
  table <- do.call(rbind, rows)
  utils::head(table, as.integer(limit %||% 8L))
}

project_recent_write <- function(entries, path = NULL) {
  file <- project_recent_file(path)
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("rcmdr-projects-", tmpdir = dirname(file))
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(entries, temporary)
  if (file.exists(file)) {
    try(file.copy(file, paste0(file, ".bak"), overwrite = TRUE),
        silent = TRUE)
  }
  if (!file.rename(temporary, file)) {
    unlink(file)
    if (!file.rename(temporary, file)) {
      stop("Could not write the recent projects list.", call. = FALSE)
    }
  }
  invisible(file)
}

#' Record a project in the recent list
#' @keywords internal
project_recent_add <- function(path, title = NULL, limit = 8L,
                               file = NULL) {
  if (!project_is_string(path, allow_empty = FALSE)) return(invisible(FALSE))
  path <- project_normalize_path(path.expand(path))
  existing <- project_recent(limit = 1000L, path = file)
  entries <- list(list(
    path = path,
    title = title %||% basename(path),
    modified = project_timestamp()
  ))
  for (i in seq_len(nrow(existing))) {
    if (!identical(existing$path[[i]], path)) {
      entries[[length(entries) + 1L]] <- list(
        path = existing$path[[i]],
        title = existing$title[[i]],
        modified = existing$modified[[i]]
      )
    }
  }
  project_recent_write(utils::head(entries, as.integer(limit %||% 8L)), file)
  invisible(TRUE)
}

#' Remove a project from the recent list
#' @keywords internal
project_recent_remove <- function(path, file = NULL) {
  existing <- project_recent(limit = 1000L, path = file)
  keep <- existing$path != project_normalize_path(path.expand(path))
  entries <- lapply(which(keep), function(i) {
    list(path = existing$path[[i]], title = existing$title[[i]],
         modified = existing$modified[[i]])
  })
  project_recent_write(entries, file)
  invisible(TRUE)
}

# -- autosave and recovery ---------------------------------------------------

#' Autosave path for the current project
#' @keywords internal
project_autosave_path <- function(state) {
  path <- state$project_path
  if (!is.null(path) && nzchar(path)) {
    return(paste0(path, ".autosave"))
  }
  directory <- file.path(dirname(project_recent_file()), "autosave")
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  name <- project_safe_name(state$project_title %||% "untitled")
  file.path(directory, paste0(name, ".", project_extension(), ".autosave"))
}

#' Autosave the current session
#' @keywords internal
project_autosave <- function(state) {
  if (!isTRUE(state$options$project_autosave)) return(invisible(FALSE))
  if (is.null(state$project_path) && !isTRUE(state$project_dirty)) {
    return(invisible(FALSE))
  }
  path <- project_autosave_path(state)
  result <- tryCatch(
    project_write(state, path),
    error = function(e) e
  )
  if (inherits(result, "error")) {
    state$project_last_error <- conditionMessage(result)
    return(invisible(FALSE))
  }
  state$project_autosave_time <- Sys.time()
  invisible(TRUE)
}

#' Remove the autosave file of the current project
#' @keywords internal
project_remove_autosave <- function(state) {
  path <- state$project_path
  if (is.null(path) || !nzchar(path)) return(invisible(FALSE))
  autosave <- paste0(path, ".autosave")
  if (file.exists(autosave)) unlink(autosave)
  state$project_autosave_time <- NULL
  invisible(TRUE)
}

#' Describe the recovery state of a project
#'
#' @param path Project file.
#' @return A list with `available`, `newer`, the two paths and their times.
#' @keywords internal
project_recovery_info <- function(path) {
  path <- project_normalize_path(path.expand(path))
  autosave <- paste0(path, ".autosave")
  info <- list(
    path = path,
    autosave = autosave,
    available = file.exists(autosave),
    project_time = if (file.exists(path)) file.info(path)$mtime else NA,
    autosave_time = if (file.exists(autosave)) file.info(autosave)$mtime else NA,
    newer = FALSE,
    project_size = if (file.exists(path)) file.info(path)$size else NA_real_,
    autosave_size = if (file.exists(autosave)) {
      file.info(autosave)$size
    } else {
      NA_real_
    }
  )
  info$newer <- isTRUE(info$available) &&
    (!isTRUE(file.exists(path)) ||
       (isTRUE(info$autosave_time > info$project_time)))
  info
}

#' Recover the autosave of a project
#'
#' The original project path is kept, so the next explicit save replaces the
#' project and removes the autosave.
#'
#' @keywords internal
project_recover <- function(state, path) {
  path <- project_normalize_path(path.expand(path))
  autosave <- paste0(path, ".autosave")
  source <- if (file.exists(autosave)) autosave else path
  project <- project_read(source)
  project_apply(state, project, path = path)
  state$project_dirty <- TRUE
  state$project_autosave_time <- if (file.exists(autosave)) {
    file.info(autosave)$mtime
  } else {
    NULL
  }
  invisible(project)
}

# -- export bundle -----------------------------------------------------------

#' Export a project bundle
#'
#' Writes a self-contained archive with the project file, its included data and
#' its plots.  `.tar.gz` is handled by base R; `.zip` needs an external `zip`
#' executable.
#'
#' @param state Application state.
#' @param file Destination archive.
#' @return The archive path, invisibly.
#' @keywords internal
project_export_bundle <- function(state, file = NULL) {
  file <- file %||% file.path(getwd(), project_file_name(
    state$project_title %||% "project-bundle"
  ))
  file <- project_normalize_path(path.expand(file))
  extension <- tolower(tools::file_ext(file))

  staging <- tempfile("rcmdr-bundle-")
  dir.create(staging, recursive = TRUE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  target <- file.path(staging, project_file_name(
    state$project_title %||% "project"
  ))
  project_write(state, target)
  writeLines(c(
    "RcmdrShiny Studio project bundle",
    "",
    "project.rcmdrproj  the session description",
    "data/              included data sets",
    "assets/            plots copied from the gallery",
    "",
    "Open the .rcmdrproj file from RcmdrShiny Studio."
  ), file.path(staging, "README.txt"))

  files <- list.files(staging, all.files = TRUE, no.. = TRUE,
                      recursive = TRUE, full.names = TRUE)
  files <- files[file.info(files)$isdir %in% FALSE]
  relative <- substring(files, nchar(staging) + 2L)
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  if (identical(extension, "zip")) {
    if (!nzchar(Sys.which("zip"))) {
      stop("Creating a .zip bundle needs the 'zip' executable; use .tar.gz.",
           call. = FALSE)
    }
    old <- setwd(staging)
    on.exit(setwd(old), add = TRUE)
    status <- utils::zip(file, files = relative, flags = "-r9X")
    if (!identical(status, 0L)) {
      stop("The zip command failed.", call. = FALSE)
    }
  } else {
    old <- setwd(staging)
    on.exit(setwd(old), add = TRUE)
    utils::tar(file, files = relative, tar = "internal",
               compression = "gzip", compression_level = 6)
  }
  invisible(file)
}

# -- session metadata --------------------------------------------------------

#' Mark the project as changed
#' @keywords internal
project_mark_dirty <- function(state) {
  if (!is.null(state$project_path)) state$project_dirty <- TRUE
  invisible(state$project_dirty)
}

#' Reset project metadata for a new project
#' @keywords internal
project_reset <- function(state, path = NULL, title = NULL) {
  now <- project_timestamp()
  state$project_path <- if (is.null(path)) NULL else {
    project_normalize_path(path.expand(path))
  }
  state$project_title <- title %||%
    if (!is.null(state$project_path)) {
      sub(paste0("\\.", project_extension(), "$"), "",
          basename(state$project_path))
    } else {
      tr("Untitled project")
    }
  state$project_created <- now
  state$project_modified <- now
  state$project_dirty <- TRUE
  state$project_models <- list()
  state$project_autosave_time <- NULL
  if (!is.null(state$project_path)) {
    project_recent_add(state$project_path, state$project_title,
                       file = state$project_recent_file)
  }
  state_touch(state)
  invisible(state$project_title)
}

#' Session project summary
#' @keywords internal
project_summary <- function(state) {
  list(
    path = state$project_path,
    title = state$project_title %||% tr("Untitled project"),
    created = state$project_created,
    modified = state$project_modified,
    dirty = isTRUE(state$project_dirty),
    datasets = length(state$datasets %||% list()),
    documents = length(state$documents %||% list()),
    plots = length(state$plots %||% list()),
    active_dataset = state$active_dataset,
    active_model = state$active_model,
    autosave = state$project_autosave_time
  )
}

# -- validation --------------------------------------------------------------

project_schema_keys <- function() {
  c("version", "created", "modified", "package_version", "title",
    "datasets", "models", "active_model", "documents", "active_document",
    "plots", "presets", "favorites", "options", "history", "path")
}

project_collection <- function(project, name, add_problem,
                               required = FALSE) {
  value <- project[[name]]
  if (is.null(value)) {
    if (isTRUE(required)) add_problem("Missing '%s' collection.", name)
    return(list())
  }
  if (!is.list(value)) {
    add_problem("'%s' must be a list.", name)
    return(list())
  }
  value
}

#' Validate a project
#'
#' The validator is pure: it never repairs the project.  [project_migrate()]
#' normalises older documents first, then the caller validates the result.
#'
#' @param project A project list.
#' @param strict Require the recommended header fields (`created`, `modified`,
#'   `package_version`).  `TRUE` for files this package wrote.
#' @return A list with `ok`, `problems` and `warnings`.
#' @keywords internal
project_validate <- function(project, strict = TRUE) {
  problems <- character()
  warnings <- character()
  add_problem <- function(...) {
    problems <<- c(problems, sprintf(...))
    invisible(NULL)
  }
  add_warning <- function(...) {
    warnings <<- c(warnings, sprintf(...))
    invisible(NULL)
  }

  if (!is.list(project)) {
    return(list(ok = FALSE,
                problems = "A project must be a list.",
                warnings = character()))
  }

  unknown <- setdiff(names(project), project_schema_keys())
  for (name in unknown) {
    add_warning("Unknown top-level field '%s'.", name)
  }

  # -- header ---------------------------------------------------------------
  version <- project$version
  if (is.null(version)) {
    add_problem("The project has no schema version.")
  } else if (!project_is_number(version) || version < 1L ||
             version != as.integer(version)) {
    add_problem("The schema version must be a positive integer.")
  } else if (as.integer(version) > project_schema_version()) {
    add_problem("Schema version %d is newer than the supported version %d.",
                as.integer(version), project_schema_version())
  }

  for (field in c("created", "modified")) {
    value <- project[[field]]
    if (is.null(value)) {
      if (isTRUE(strict)) add_problem("The '%s' timestamp is missing.", field)
    } else if (!project_is_timestamp(value)) {
      add_problem("The '%s' timestamp is not ISO-8601.", field)
    }
  }
  if (!is.null(project$package_version) &&
      !project_is_string(project$package_version, allow_empty = FALSE)) {
    add_problem("'package_version' must be a non-empty string.")
  } else if (is.null(project$package_version) && isTRUE(strict)) {
    add_problem("'package_version' is missing.")
  }
  if (!is.null(project$title) && !project_is_string(project$title)) {
    add_problem("'title' must be a string.")
  }

  # -- data sets ------------------------------------------------------------
  datasets <- project_collection(project, "datasets", add_problem = add_problem)
  dataset_names <- character()
  active_datasets <- 0L
  for (i in seq_along(datasets)) {
    entry <- datasets[[i]]
    label <- sprintf("datasets[%d]", i)
    if (!is.list(entry)) {
      add_problem("%s must be a list.", label)
      next
    }
    name <- entry$name
    if (!project_is_string(name, allow_empty = FALSE)) {
      add_problem("%s has no name.", label)
    } else {
      label <- sprintf("data set '%s'", name)
      if (name %in% dataset_names) {
        add_problem("Duplicate data set name '%s'.", name)
      }
      dataset_names <- c(dataset_names, name)
    }
    if (!project_is_string(entry$source, allow_empty = FALSE)) {
      add_problem("%s needs a 'source' path.", label)
    }
    for (field in c("include", "active")) {
      if (!is.null(entry[[field]]) && !project_is_flag(entry[[field]])) {
        add_problem("%s: '%s' must be TRUE or FALSE.", label, field)
      }
    }
    if (isTRUE(entry$active)) active_datasets <- active_datasets + 1L
    dictionary <- entry$dictionary
    if (!is.null(dictionary)) {
      if (!is.list(dictionary)) {
        add_problem("%s: 'dictionary' must be a list.", label)
      } else {
        for (variable in names(dictionary)) {
          if (!nzchar(variable)) {
            add_problem("%s: a dictionary entry has no variable name.", label)
            next
          }
          info <- dictionary[[variable]]
          if (!is.list(info)) {
            add_problem("%s: dictionary for '%s' must be a list.",
                        label, variable)
            next
          }
          for (field in names(info)) {
            if (!field %in% c("label", "units", "description")) {
              add_warning("%s: unknown dictionary field '%s' for '%s'.",
                          label, field, variable)
            } else if (!is.null(info[[field]]) &&
                       !project_is_string(info[[field]])) {
              add_problem("%s: dictionary field '%s' for '%s' must be text.",
                          label, field, variable)
            }
          }
        }
      }
    }
  }
  if (active_datasets > 1L) {
    add_problem("At most one data set can be active.")
  }

  # -- models ---------------------------------------------------------------
  models <- project_collection(project, "models", add_problem = add_problem)
  model_names <- character()
  for (i in seq_along(models)) {
    entry <- models[[i]]
    label <- sprintf("models[%d]", i)
    if (!is.list(entry)) {
      add_problem("%s must be a list.", label)
      next
    }
    if (!project_is_string(entry$name, allow_empty = FALSE)) {
      add_problem("%s has no name.", label)
    } else {
      label <- sprintf("model '%s'", entry$name)
      if (entry$name %in% model_names) {
        add_problem("Duplicate model name '%s'.", entry$name)
      }
      model_names <- c(model_names, entry$name)
    }
    if (!project_is_string(entry$class, allow_empty = FALSE)) {
      add_problem("%s needs a 'class'.", label)
    }
    for (field in c("formula", "data")) {
      if (!is.null(entry[[field]]) &&
          !project_is_string(entry[[field]])) {
        add_problem("%s: '%s' must be text.", label, field)
      }
    }
  }
  active_model <- project$active_model
  if (!is.null(active_model) && nzchar(as.character(active_model)) &&
      !as.character(active_model) %in% model_names) {
    add_problem("The active model '%s' is not in the model list.",
                as.character(active_model))
  }
  if (!is.null(active_model) && !project_is_string(active_model)) {
    add_problem("'active_model' must be a model name or NULL.")
  }

  # -- documents ------------------------------------------------------------
  documents <- project_collection(project, "documents",
                                  add_problem = add_problem)
  document_ids <- character()
  active_documents <- 0L
  for (i in seq_along(documents)) {
    entry <- documents[[i]]
    label <- sprintf("documents[%d]", i)
    if (!is.list(entry)) {
      add_problem("%s must be a list.", label)
      next
    }
    id <- entry$id
    if (!project_is_string(id, allow_empty = FALSE)) {
      add_problem("%s has no id.", label)
    } else {
      label <- sprintf("document '%s'", id)
      if (grepl("[/\\\\]", id)) {
        add_problem("%s: the id must not contain path separators.", label)
      }
      if (id %in% document_ids) {
        add_problem("Duplicate document id '%s'.", id)
      }
      document_ids <- c(document_ids, id)
    }
    mode <- entry$mode %||% "r"
    if (!project_is_string(mode, allow_empty = FALSE) ||
        !mode %in% document_modes()) {
      mode_label <- if (project_is_string(mode)) mode else
        paste(as.character(mode), collapse = ", ")
      add_problem("%s: unknown document mode '%s'.", label, mode_label)
    }
    if (!project_is_string(entry$text)) {
      add_problem("%s: 'text' must be a string.", label)
    }
    if (!is.null(entry$path) && !project_is_string(entry$path)) {
      add_problem("%s: 'path' must be text.", label)
    }
    if (!is.null(entry$active) && !project_is_flag(entry$active)) {
      add_problem("%s: 'active' must be TRUE or FALSE.", label)
    }
    if (isTRUE(entry$active)) active_documents <- active_documents + 1L
  }
  if (active_documents > 1L) {
    add_problem("At most one document can be active.")
  }
  active_document <- project$active_document
  if (!is.null(active_document) && !project_is_string(active_document)) {
    add_problem("'active_document' must be a document id or NULL.")
  } else if (!is.null(active_document) &&
             !active_document %in% document_ids) {
    add_problem("The active document '%s' is not in the document list.",
                active_document)
  }

  # -- plots ----------------------------------------------------------------
  plots <- project_collection(project, "plots", add_problem = add_problem)
  plot_ids <- character()
  for (i in seq_along(plots)) {
    entry <- plots[[i]]
    label <- sprintf("plots[%d]", i)
    if (!is.list(entry)) {
      add_problem("%s must be a list.", label)
      next
    }
    id <- entry$id
    if (!project_is_string(id, allow_empty = FALSE)) {
      add_problem("%s has no id.", label)
    } else {
      label <- sprintf("plot '%s'", id)
      if (id %in% plot_ids) add_problem("Duplicate plot id '%s'.", id)
      plot_ids <- c(plot_ids, id)
    }
    file <- entry$file
    if (!is.null(file)) {
      if (!project_is_string(file, allow_empty = FALSE)) {
        add_problem("%s: 'file' must be text.", label)
      } else if (project_path_absolute(file)) {
        add_problem("%s: the plot file must be relative to the project.",
                    label)
      } else if (project_path_escapes(file)) {
        add_problem("%s: the plot file must not leave the project folder.",
                    label)
      } else if (!startsWith(file, "assets/") &&
                 !startsWith(file, "assets\\\\")) {
        add_warning("%s: the plot file is stored outside 'assets/'.", label)
      }
    }
    if (!is.null(entry$spec) && !is.list(entry$spec)) {
      add_problem("%s: 'spec' must be a list.", label)
    }
    if (!is.null(entry$title) && !project_is_string(entry$title)) {
      add_problem("%s: 'title' must be text.", label)
    }
    if (!is.null(entry$pinned) && !project_is_flag(entry$pinned)) {
      add_problem("%s: 'pinned' must be TRUE or FALSE.", label)
    }
  }

  # -- presets --------------------------------------------------------------
  presets <- project$presets
  if (!is.null(presets)) {
    if (!is.list(presets)) {
      add_problem("'presets' must be a list.")
    } else {
      for (dialog in names(presets)) {
        if (!nzchar(dialog)) {
          add_problem("A preset group has no dialog id.")
          next
        }
        group <- presets[[dialog]]
        if (!is.list(group)) {
          add_problem("Presets for '%s' must be a list.", dialog)
          next
        }
        for (preset in names(group)) {
          if (!nzchar(preset)) {
            add_problem("Presets for '%s' contain an unnamed entry.", dialog)
          } else if (!is.list(group[[preset]])) {
            add_problem("Preset '%s' for '%s' must be a list.",
                        preset, dialog)
          }
        }
      }
    }
  }

  # -- favourites and options ----------------------------------------------
  favorites <- project$favorites
  if (!is.null(favorites)) {
    if (!is.character(favorites) || anyNA(favorites)) {
      add_problem("'favorites' must be a character vector of command ids.")
    } else if (any(!nzchar(favorites))) {
      add_problem("'favorites' contains an empty command id.")
    } else if (anyDuplicated(favorites)) {
      add_warning("'favorites' contains duplicates.")
    }
  }

  options <- project$options
  if (!is.null(options)) {
    if (!is.list(options)) {
      add_problem("'options' must be a list.")
    } else {
      known_options <- c("ui_mode", "theme", "language")
      for (name in setdiff(names(options), known_options)) {
        add_warning("Unknown project option '%s'.", name)
      }
      if (!is.null(options$ui_mode) &&
          !(project_is_string(options$ui_mode) &&
            options$ui_mode %in% c("studio", "classic"))) {
        add_problem("'options$ui_mode' must be 'studio' or 'classic'.")
      }
      if (!is.null(options$theme) &&
          !(project_is_string(options$theme) &&
            options$theme %in% ui_themes())) {
        add_problem("'options$theme' is not a supported theme.")
      }
      if (!is.null(options$language)) {
        languages <- tryCatch(available_languages(), error = function(e) NULL)
        if (!project_is_string(options$language, allow_empty = FALSE)) {
          add_problem("'options$language' must be a language code.")
        } else if (!is.null(languages) &&
                   !options$language %in% languages) {
          add_problem("'options$language' is not an available language.")
        }
      }
    }
  }

  # -- history --------------------------------------------------------------
  history <- project$history
  if (!is.null(history)) {
    if (!is.list(history)) {
      add_problem("'history' must be a list.")
    } else {
      for (name in setdiff(names(history), c("include", "entries"))) {
        add_warning("Unknown history field '%s'.", name)
      }
      if (!is.null(history$include) && !project_is_flag(history$include)) {
        add_problem("'history$include' must be TRUE or FALSE.")
      }
      if (!is.null(history$entries)) {
        if (!is.list(history$entries)) {
          add_problem("'history$entries' must be a list.")
        } else {
          for (i in seq_along(history$entries)) {
            entry <- history$entries[[i]]
            if (!is.list(entry)) {
              add_problem("history entry %d must be a list.", i)
            } else if (!project_is_string(entry$command,
                                          allow_empty = FALSE)) {
              add_problem("history entry %d has no command.", i)
            }
          }
        }
      }
    }
  }

  list(ok = length(problems) == 0L,
       problems = unique(problems),
       warnings = unique(warnings))
}

#' Validate a project or stop
#' @param project A project list.
#' @return The project, invisibly.
#' @keywords internal
project_validate_or_stop <- function(project, strict = TRUE) {
  result <- project_validate(project, strict = strict)
  if (!result$ok) {
    stop("Invalid project:\n",
         paste0("  - ", result$problems, collapse = "\n"),
         call. = FALSE)
  }
  invisible(project)
}

# -- normalisation and migration --------------------------------------------

project_fill_names <- function(entries, key) {
  if (!is.list(entries) || length(entries) == 0L) return(entries)
  keys <- names(entries)
  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    if (!is.list(entry)) next
    if (is.null(entry[[key]]) && !is.null(keys) && nzchar(keys[[i]])) {
      entry[[key]] <- keys[[i]]
      entries[[i]] <- entry
    }
  }
  unname(entries)
}

#' Normalise a project to the canonical in-memory shape
#'
#' Fills the optional collections, restores names from named lists and merges
#' the option defaults.  It never drops information: an unknown field is kept
#' so that the validator can report it.
#'
#' @param project A project list.
#' @return The normalised project.
#' @keywords internal
project_normalize <- function(project) {
  if (!is.list(project)) return(project)

  for (field in c("datasets", "models", "documents", "plots")) {
    if (is.null(project[[field]]) || !is.list(project[[field]])) {
      project[[field]] <- list()
    }
  }
  project$datasets <- project_fill_names(project$datasets, "name")
  project$models <- project_fill_names(project$models, "name")
  project$documents <- project_fill_names(project$documents, "id")
  project$plots <- project_fill_names(project$plots, "id")

  favorites <- project$favorites
  if (is.null(favorites) ||
      (is.list(favorites) && length(favorites) == 0L)) {
    project$favorites <- character()
  } else if (is.character(favorites)) {
    project$favorites <- unique(favorites[!is.na(favorites) & nzchar(favorites)])
  }

  if (!is.list(project$presets)) project$presets <- list()
  if (is.list(project$options)) {
    defaults <- project_options()
    for (name in names(defaults)) {
      if (is.null(project$options[[name]])) {
        project$options[[name]] <- defaults[[name]]
      }
    }
  } else {
    project$options <- project_options()
  }
  if (is.list(project$history)) {
    if (is.null(project$history$include)) project$history$include <- FALSE
  } else {
    project$history <- list(include = FALSE)
  }

  project$active_model <- project$active_model %||% NULL
  project$active_document <- project$active_document %||% NULL
  project
}

# Migration step from the pre-schema draft to version 1.  No released file used
# version 0; it covers drafts written by the Wave 0 spike and hand-written
# project summaries.
project_migrate_v0 <- function(project) {
  aliases <- c(data = "datasets", data_sets = "datasets", docs = "documents",
               figures = "plots", favourites = "favorites")
  for (alias in names(aliases)) {
    target <- aliases[[alias]]
    if (is.null(project[[target]]) && !is.null(project[[alias]])) {
      project[[target]] <- project[[alias]]
    }
  }
  project[c("data", "data_sets", "docs", "figures", "favourites")] <- NULL

  active_dataset <- project$active_dataset
  if (!is.null(active_dataset) && is.list(project$datasets)) {
    project$datasets <- lapply(project$datasets, function(entry) {
      if (is.list(entry)) {
        entry$active <- identical(entry$name, active_dataset)
      }
      entry
    })
  }
  project$active_dataset <- NULL
  if (is.null(project$active_model) && !is.null(project$model)) {
    project$active_model <- project$model
  }
  project$model <- NULL

  now <- project_timestamp()
  if (is.null(project$created)) project$created <- now
  if (is.null(project$modified)) project$modified <- project$created
  if (is.null(project$package_version)) {
    project$package_version <- project_package_version()
  }
  if (is.null(project$title)) project$title <- ""
  project$version <- 1L
  project
}

#' Migration steps keyed by the version they upgrade from
#' @keywords internal
project_migrations <- function() {
  list(`0` = project_migrate_v0)
}

#' Migrate a project to the current schema version
#'
#' Version 0 covers pre-schema drafts: `data`/`data_sets` are renamed to
#' `datasets`, `active_dataset` becomes the `active` flag of an entry, and the
#' missing header fields are filled.  A document from a newer version is
#' rejected, never silently rewritten.
#'
#' @param project A project list, possibly from an older version.
#' @return A project at [project_schema_version()], normalised.
#' @keywords internal
project_migrate <- function(project) {
  if (!is.list(project)) {
    stop("A project must be a list.", call. = FALSE)
  }
  version <- project$version
  if (is.null(version) || (length(version) == 1L && is.na(version))) {
    version <- 0L
  }
  if (!project_is_number(version) || version < 0L ||
      version != as.integer(version)) {
    stop("The project schema version is not a non-negative integer.",
         call. = FALSE)
  }
  version <- as.integer(version)
  current <- project_schema_version()
  if (version > current) {
    stop(sprintf(
      "The project uses schema version %d, but this build supports up to %d.",
      version, current
    ), call. = FALSE)
  }

  original <- version
  steps <- project_migrations()
  while (version < current) {
    step <- steps[[as.character(version)]]
    if (is.null(step)) {
      stop(sprintf("No migration from schema version %d.", version),
           call. = FALSE)
    }
    project <- step(project)
    version <- version + 1L
    project$version <- as.integer(version)
  }

  project <- project_normalize(project)
  project$version <- as.integer(current)
  if (original < current) {
    attr(project, "migrated_from") <- original
  }
  project
}

# -- paths -------------------------------------------------------------------

#' Lexically normalise a path
#'
#' `normalizePath()` leaves `..` untouched when the target does not exist yet,
#' which would defeat the containment checks.  This helper resolves `.` and
#' `..` segments without touching the file system.
#'
#' @keywords internal
project_normalize_path <- function(path) {
  if (!project_is_string(path) || !nzchar(path)) return(path)
  path <- gsub("\\\\", "/", path)
  absolute <- startsWith(path, "/")
  drive <- ""
  if (grepl("^[A-Za-z]:", path)) {
    drive <- substr(path, 1L, 2L)
    path <- substring(path, 3L)
    absolute <- TRUE
  }
  segments <- strsplit(path, "/", fixed = TRUE)[[1L]]
  out <- character()
  for (segment in segments) {
    if (!nzchar(segment) || identical(segment, ".")) next
    if (identical(segment, "..")) {
      if (length(out) > 0L && !identical(out[[length(out)]], "..")) {
        out <- out[-length(out)]
      } else if (!absolute) {
        out <- c(out, "..")
      }
      next
    }
    out <- c(out, segment)
  }
  result <- paste(out, collapse = "/")
  if (absolute) result <- paste0("/", result)
  if (nzchar(drive)) result <- paste0(drive, "/", result)
  if (!nzchar(result)) result <- if (absolute) "/" else "."
  result
}

#' Is a path absolute?
#' @keywords internal
project_path_absolute <- function(path) {
  if (!project_is_string(path, allow_empty = FALSE)) return(FALSE)
  grepl("^(/|~|[A-Za-z]:[\\\\/]|\\\\\\\\)", path)
}

#' Does a relative path climb out of its folder?
#' @keywords internal
project_path_escapes <- function(path) {
  if (!project_is_string(path)) return(FALSE)
  segments <- strsplit(gsub("\\\\", "/", path), "/", fixed = TRUE)[[1L]]
  any(segments == "..")
}

#' Make a path relative to a root when it lives inside it
#'
#' Paths outside the root are returned absolute: the schema never invents
#' `..` chains, because a project must not silently reach outside its folder.
#'
#' @param path A file path.
#' @param root The project directory.
#' @keywords internal
project_relative_path <- function(path, root) {
  if (!project_is_string(path) || !nzchar(path)) return(path)
  if (!project_path_absolute(path)) {
    return(sub("^\\./", "", path))
  }
  full <- project_normalize_path(path.expand(path))
  base <- sub("/+$", "", project_normalize_path(path.expand(root)))
  if (identical(full, base)) return(".")
  prefix <- paste0(base, "/")
  if (startsWith(full, prefix)) {
    return(substring(full, nchar(prefix) + 1L))
  }
  full
}

#' Resolve a project-relative path against its root
#'
#' @param path A project-relative path.  Absolute paths are returned unchanged.
#' @param root The project directory.
#' @keywords internal
project_resolve_path <- function(path, root) {
  if (!project_is_string(path) || !nzchar(path)) return(path)
  if (project_path_absolute(path)) {
    return(project_normalize_path(path.expand(path)))
  }
  project_normalize_path(file.path(root, path))
}

#' Is a path inside a root folder?
#' @keywords internal
project_path_inside <- function(path, root) {
  if (!project_is_string(path) || !nzchar(path)) return(FALSE)
  full <- project_resolve_path(path, root)
  base <- sub("/+$", "", project_normalize_path(path.expand(root)))
  identical(full, base) || startsWith(full, paste0(base, "/"))
}

#' Assets folder of a project file
#' @keywords internal
project_assets_dir <- function(path) {
  file.path(dirname(as.character(path)), "assets")
}
