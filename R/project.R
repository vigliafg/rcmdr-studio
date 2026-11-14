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
                               pinned = FALSE) {
  list(
    id = as.character(id),
    file = if (is.null(file)) NULL else as.character(file),
    title = if (is.null(title)) NULL else as.character(title),
    spec = spec %||% NULL,
    pinned = isTRUE(pinned)
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
            options$theme %in% c("system", "light", "dark", "contrast"))) {
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
      for (name in setdiff(names(history), "include")) {
        add_warning("Unknown history field '%s'.", name)
      }
      if (!is.null(history$include) && !project_is_flag(history$include)) {
        add_problem("'history$include' must be TRUE or FALSE.")
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
  if (is.null(favorites)) {
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
