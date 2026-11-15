# Diagnostic report ----------------------------------------------------------
#
# A small, pasteable report attached to bug reports.  It contains versions and
# configuration only: no data, no script and no environment contents.

#' Build a diagnostic report
#'
#' Collects the R and RcmdrShiny versions, the loaded plugins, the core package
#' versions that matter for graphics and modelling, and the session options that
#' change generated commands.
#'
#' @param state Optional application state.  When supplied, the report also
#'   includes the UI mode, feature flags, project, history and caches.
#' @return A named list.
#' @export
diagnostics_report <- function(state = NULL) {
  package_version <- function(package) {
    tryCatch(as.character(utils::packageVersion(package)),
             error = function(e) NA_character_)
  }

  packages <- c("RcmdrShiny", "RcmdrMisc", "car", "effects", "lattice",
                "ggplot2", "rgl", "survival", "FactoMineR", "commonmark",
                "yaml")
  versions <- vapply(packages, package_version, character(1))

  report <- list(
    r_version = R.version.string,
    platform = R.version$platform,
    rcmdrshiny = package_version("RcmdrShiny"),
    language = tryCatch(current_language(), error = function(e) "en"),
    plugins = tryCatch(as.character(list_plugins()), error = function(e) character()),
    plugin_failures = tryCatch(plugin_failures(), error = function(e) NULL),
    packages = versions,
    help_topics = tryCatch(length(help_topics()), error = function(e) 0L),
    options = list(
      digits = getOption("digits"),
      stringsAsFactors = getOption("stringsAsFactors"),
      help_markdown = getOption("RcmdrShiny.help.markdown", "auto"),
      help_yaml = getOption("RcmdrShiny.help.yaml", "auto")
    )
  )

  if (!is.null(state)) {
    report$ui_mode <- tryCatch(ui_mode(state), error = function(e) "studio")
    report$features <- names(Filter(
      isTRUE, state$options$features %||% list()
    ))
    report$project <- tryCatch(project_summary(state),
                               error = function(e) NULL)
    report$history <- length(state$history %||% list())
    report$last_error <- state$last_error
    report$caches <- tryCatch(cache_stats(), error = function(e) NULL)
    report$pending_plugins <- tryCatch(plugins_pending(),
                                       error = function(e) character())
  }
  report
}

#' Format a diagnostic report as text
#'
#' @param report Report returned by [diagnostics_report()].
#' @return A character vector, one line per item.
#' @export
format_diagnostics <- function(report = diagnostics_report()) {
  lines <- c(
    "RcmdrShiny diagnostic report",
    "----------------------------",
    sprintf("R: %s", report$r_version),
    sprintf("Platform: %s", report$platform),
    sprintf("RcmdrShiny: %s", report$rcmdrshiny),
    sprintf("Language: %s", report$language),
    sprintf("Help topics: %d", report$help_topics),
    sprintf("Plugins: %s",
            if (length(report$plugins) == 0L) {
              "(none)"
            } else {
              paste(report$plugins, collapse = ", ")
            }),
    if (length(report$pending_plugins %||% character()) > 0L) {
      sprintf("Pending plugins: %s",
              paste(report$pending_plugins, collapse = ", "))
    } else {
      NULL
    },
    if (!is.null(report$plugin_failures) && nrow(report$plugin_failures) > 0L) {
      sprintf("Plugin failures: %s",
              paste(sprintf("%s (%s)", report$plugin_failures$name,
                            report$plugin_failures$message), collapse = ", "))
    } else {
      NULL
    },
    if (!is.null(report$ui_mode)) sprintf("UI mode: %s", report$ui_mode),
    if (length(report$features %||% character()) > 0L) {
      sprintf("Feature flags: %s", paste(report$features, collapse = ", "))
    } else {
      NULL
    },
    "",
    "Package versions:",
    sprintf("  %s: %s", names(report$packages),
            ifelse(is.na(report$packages), "(not installed)", report$packages)),
    "",
    "Options:",
    sprintf("  %s: %s", names(report$options),
            vapply(report$options, function(value) {
              paste(format(value), collapse = ", ")
            }, character(1)))
  )
  if (!is.null(report$project)) {
    lines <- c(
      lines, "", "Project:",
      sprintf("  title: %s", report$project$title %||% "(untitled)"),
      sprintf("  path: %s", report$project$path %||% "(not saved)"),
      sprintf("  dirty: %s", if (isTRUE(report$project$dirty)) "yes" else "no"),
      sprintf("  data sets: %d", report$project$datasets),
      sprintf("  documents: %d", report$project$documents),
      sprintf("  plots: %d", report$project$plots)
    )
  }
  if (!is.null(report$caches) && nrow(report$caches) > 0L) {
    lines <- c(
      lines, "", "Caches:",
      sprintf("  %s: %s (%d entries)", report$caches$cache,
              ifelse(report$caches$ready, "warm", "cold"),
              report$caches$entries)
    )
  }
  if (!is.null(report$history)) {
    lines <- c(lines, "", sprintf("History: %d entries", report$history))
  }
  if (!is.null(report$last_error)) {
    lines <- c(lines, sprintf("Last error: %s", report$last_error))
  }
  lines
}

#' Text of the diagnostic report
#'
#' @param state Optional application state.
#' @return A character scalar.
#' @keywords internal
diagnostics_report_text <- function(state = NULL) {
  paste(format_diagnostics(diagnostics_report(state)), collapse = "\n")
}

#' GitHub issue URL pre-filled with the diagnostic report
#'
#' @param report Report from [diagnostics_report()].
#' @param base Repository issue URL.
#' @return A URL string.
#' @keywords internal
diagnostics_issue_url <- function(report = diagnostics_report(),
                                  base = "https://github.com/vigliafg/rcmdr-studio/issues/new") {
  body <- paste(format_diagnostics(report), collapse = "\n")
  body <- paste0(
    "### What happened\n\n<!-- Describe the problem -->\n\n",
    "### Diagnostic report\n\n```text\n", body, "\n```\n"
  )
  title <- "RcmdrShiny Studio issue"
  paste0(base,
         "?title=", utils::URLencode(title, reserved = TRUE),
         "&body=", utils::URLencode(body, reserved = TRUE))
}
