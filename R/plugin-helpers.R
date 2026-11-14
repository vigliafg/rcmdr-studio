# Plugin helpers ------------------------------------------------------------
#
# Small, stable helpers that plugin packages can use without reaching into
# unexported internals.  They complement the state accessors exported from
# state.R (active_dataset(), active_model(), dataset(), variables(), ...).

#' Build a formula from variable names
#'
#' Plugin dialogs collect variable names from widgets and need to turn them
#' into the formula strings used by Rcmdr commands.
#'
#' @param response Optional response variable name.
#' @param predictors Character vector of predictor names.
#' @param interactions Optional list of character vectors.  A vector with more
#'   than one element becomes an interaction term such as `(a * b)`.
#' @return A formula string, for example `"y ~ x1 + x2"`.
#' @export
plugin_formula <- function(response = NULL, predictors = character(),
                           interactions = list()) {
  predictors <- as.character(predictors %||% character())
  terms <- predictors[nzchar(predictors)]

  for (interaction in interactions %||% list()) {
    interaction <- as.character(interaction)
    interaction <- interaction[nzchar(interaction)]
    if (length(interaction) == 0L) next
    terms <- c(
      terms,
      if (length(interaction) == 1L) {
        interaction
      } else {
        paste0("(", paste(interaction, collapse = " * "), ")")
      }
    )
  }

  rhs <- paste(unique(terms), collapse = " + ")
  if (is.null(response) || !nzchar(response)) {
    rhs
  } else {
    paste0(response, " ~ ", if (nzchar(rhs)) rhs else "1")
  }
}

#' Variable names by type
#'
#' `variables()` returns all variables in the active data set;
#' `numeric_variables()` and `factor_variables()` filter them.  Factors,
#' logicals and character variables are all treated as categorical, matching
#' Rcmdr's menu predicates.
#'
#' @param state Application state created by [AppState()].
#' @return A character vector of variable names.
#' @name plugin-variables
NULL

#' Active data frame
#'
#' Returns the active data frame, or `NULL` when no data set is active.
#'
#' @param state Application state created by [AppState()].
#' @return A data frame or `NULL`.
#' @name plugin-dataset
NULL

# -- Plugin SDK v2 ------------------------------------------------------------
#
# The 15 bundled modules are first-party.  Their contract is internal and
# versioned with the application: stable menu ids, the dialog specification and
# the extension registries below.  There is no external compatibility promise.

#' Version of the plugin contract
#' @return An integer scalar.
#' @export
plugin_api_version <- function() 2L

#' Module identifier for a plugin name
#' @keywords internal
plugin_module_id <- function(name) {
  name <- sub("^RcmdrShinyPlugin\\.", "", as.character(name %||% ""))
  tolower(gsub("[^A-Za-z0-9]+", "_", name))
}

#' Describe the plugin contract
#'
#' @return A list with the version and the stable fields a module may rely on.
#' @export
plugin_contract <- function() {
  list(
    api_version = plugin_api_version(),
    menu = c("module_id", "menu_id", "item_id", "command_id"),
    dialog = c("id", "title", "ui", "on_ok", "observers", "help",
               "help_topic", "size", "preview"),
    extension = c("component", "preset", "workflow", "chart_type",
                  "report_template", "help_examples")
  )
}

.plugin_extensions <- new.env(parent = emptyenv())
.plugin_extensions$components <- list()
.plugin_extensions$presets <- list()
.plugin_extensions$workflows <- list()
.plugin_extensions$chart_types <- list()
.plugin_extensions$report_templates <- list()

#' Reset the plugin extension registries
#' @keywords internal
plugin_extensions_reset <- function() {
  .plugin_extensions$components <- list()
  .plugin_extensions$presets <- list()
  .plugin_extensions$workflows <- list()
  .plugin_extensions$chart_types <- list()
  .plugin_extensions$report_templates <- list()
  invisible(NULL)
}

#' Register or render a plugin UI component
#'
#' With `render` supplied, registers a component factory.  Without it, renders
#' the registered component with the supplied arguments.
#'
#' @param name Component name.
#' @param ... Arguments passed to the component factory, or `render` alone.
#' @param render A function returning a Shiny tag.
#' @return The registered name, or the rendered tag.
#' @export
plugin_ui_component <- function(name, ..., render = NULL) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("A component name must be a single non-empty string.", call. = FALSE)
  }
  if (!is.null(render)) {
    if (!is.function(render)) {
      stop("`render` must be a function.", call. = FALSE)
    }
    .plugin_extensions$components[[name]] <- render
    return(invisible(name))
  }
  component <- .plugin_extensions$components[[name]]
  if (is.null(component)) {
    stop(sprintf("Unknown plugin component: %s", name), call. = FALSE)
  }
  do.call(component, list(...))
}

#' Preview a plugin dialog without opening a session
#'
#' @param spec A dialog specification from [plugin_dialog()].
#' @return A Shiny tag with the dialog body.
#' @export
plugin_dialog_preview <- function(spec) {
  if (!is.list(spec) || !is.function(spec$ui)) {
    stop("`spec` must be a dialog specification.", call. = FALSE)
  }
  state <- AppState(new.env())
  body <- tryCatch(spec$ui(state, list()), error = function(e) {
    htmltools::tags$p(class = "text-danger", conditionMessage(e))
  })
  htmltools::tags$div(class = "rcmdr-plugin-preview", body)
}

#' Register a preset supplied by a plugin
#' @export
plugin_register_preset <- function(dialog_id, name, values) {
  if (!is.character(dialog_id) || length(dialog_id) != 1L ||
      !nzchar(dialog_id)) {
    stop("A preset needs a dialog id.", call. = FALSE)
  }
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("A preset needs a name.", call. = FALSE)
  }
  if (!is.list(values)) values <- list()
  group <- .plugin_extensions$presets[[dialog_id]] %||% list()
  group[[name]] <- values
  .plugin_extensions$presets[[dialog_id]] <- group
  invisible(name)
}

#' Presets registered by plugins for a dialog
#' @keywords internal
plugin_presets_for <- function(dialog_id) {
  .plugin_extensions$presets[[dialog_id]] %||% list()
}

#' Register a guided workflow supplied by a plugin
#' @export
plugin_register_workflow <- function(workflow) {
  if (is.null(workflow$id) || !nzchar(workflow$id)) {
    stop("A workflow needs an id.", call. = FALSE)
  }
  if (is.null(workflow$title) || is.null(workflow$steps)) {
    stop("A workflow needs a title and steps.", call. = FALSE)
  }
  .plugin_extensions$workflows[[workflow$id]] <- workflow
  invisible(workflow$id)
}

#' Workflows registered by plugins
#' @keywords internal
plugin_workflows <- function() .plugin_extensions$workflows

#' Register a chart type supplied by a plugin
#' @export
plugin_register_chart_type <- function(chart_type) {
  id <- chart_type$id %||% NULL
  if (is.null(id) || !nzchar(id)) {
    stop("A chart type needs an id.", call. = FALSE)
  }
  if (is.null(chart_type$label) || is.null(chart_type$group)) {
    stop("A chart type needs a label and a group.", call. = FALSE)
  }
  .plugin_extensions$chart_types[[id]] <- chart_type
  invisible(id)
}

#' Chart types registered by plugins
#' @keywords internal
plugin_chart_types <- function() .plugin_extensions$chart_types

#' Register a report template supplied by a plugin
#' @export
plugin_register_report_template <- function(template) {
  if (is.null(template$id) || !nzchar(template$id)) {
    stop("A report template needs an id.", call. = FALSE)
  }
  if (!is.function(template$build)) {
    stop("A report template needs a build function.", call. = FALSE)
  }
  .plugin_extensions$report_templates[[template$id]] <- template
  invisible(template$id)
}

#' Report templates registered by plugins
#' @keywords internal
plugin_report_templates <- function() .plugin_extensions$report_templates

#' Add runnable examples to an existing help topic
#'
#' @param topic_id Canonical, alias or short topic id.
#' @param examples A list of example specifications accepted by the help
#'   manifest, or a character vector of code snippets.
#' @return The canonical topic id, invisibly.
#' @export
plugin_help_try_it <- function(topic_id, examples) {
  topic <- help_topic(topic_id)
  if (is.null(topic)) {
    stop(sprintf("Unknown help topic: %s", topic_id), call. = FALSE)
  }
  parsed <- help_parse_examples(examples)
  if (length(parsed) == 0L) return(invisible(topic$id))
  current <- .help_registry$topics[[topic$id]]
  existing <- current$examples %||% list()
  for (example in parsed) {
    example$index <- length(existing) + 1L
    existing <- c(existing, list(example))
  }
  current$examples <- existing
  if (length(current$languages) > 0L) {
    for (language in names(current$languages)) {
      entry <- current$languages[[language]]
      entry$examples <- c(entry$examples %||% list(), parsed)
      current$languages[[language]] <- entry
    }
  }
  .help_registry$topics[[topic$id]] <- current
  .help_registry$revision <- .help_registry$revision + 1L
  if (is.function(help_index_reset)) help_index_reset()
  invisible(topic$id)
}

#' Summary of plugin extensions for health and diagnostics
#' @keywords internal
plugin_extensions <- function() {
  list(
    components = names(.plugin_extensions$components),
    presets = names(.plugin_extensions$presets),
    workflows = names(.plugin_extensions$workflows),
    chart_types = names(.plugin_extensions$chart_types),
    report_templates = names(.plugin_extensions$report_templates)
  )
}
