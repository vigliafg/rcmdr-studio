# Health panel ---------------------------------------------------------------
#
# The health panel answers one question: is the environment able to run the
# workbench?  It reports versions, optional packages, plugins, catalogues,
# caches, the current project and the last error.  It never changes state.

health_optional_packages <- function() {
  c("car", "effects", "lattice", "ggplot2", "rgl", "survival",
    "FactoMineR", "commonmark", "yaml", "rmarkdown", "knitr", "DT",
    "shinytest2")
}

health_package_version <- function(package) {
  tryCatch(as.character(utils::packageVersion(package)),
           error = function(e) NA_character_)
}

#' Collect the health status of the session
#'
#' @param state Optional application state.
#' @return A named list.
#' @keywords internal
health_status <- function(state = NULL) {
  optional <- health_optional_packages()
  versions <- vapply(optional, health_package_version, character(1))
  pandoc <- tryCatch(rmarkdown::pandoc_available(), error = function(e) FALSE)
  latex <- nzchar(Sys.which("pdflatex"))
  plugins <- tryCatch(as.character(list_plugins()),
                      error = function(e) character())
  pending <- tryCatch(as.character(plugins_pending()),
                      error = function(e) character())
  topics <- tryCatch(nrow(help_catalog()), error = function(e) 0L)
  caches <- tryCatch(cache_stats(), error = function(e) NULL)

  project <- if (!is.null(state)) {
    tryCatch(project_summary(state), error = function(e) NULL)
  } else {
    NULL
  }
  history <- if (!is.null(state)) length(state$history %||% list()) else 0L
  last_error <- if (!is.null(state)) state$last_error else NULL
  started <- if (!is.null(state)) state$session_started else NULL
  uptime <- if (!is.null(started)) {
    as.numeric(difftime(Sys.time(), started, units = "secs"))
  } else {
    NA_real_
  }
  flags <- if (!is.null(state)) {
    names(Filter(isTRUE, state$options$features %||% list()))
  } else {
    character()
  }

  list(
    rcmdrshiny = health_package_version("RcmdrShiny"),
    r_version = R.version.string,
    platform = R.version$platform,
    pandoc = isTRUE(pandoc),
    latex = isTRUE(latex),
    optional_packages = versions,
    plugins = plugins,
    pending_plugins = pending,
    plugin_failures = tryCatch(plugin_failures(),
                               error = function(e) NULL),
    plugin_versions = vapply(plugins, function(package) {
      health_package_version(package)
    }, character(1)),
    help_topics = as.integer(topics),
    caches = caches,
    project = project,
    history = as.integer(history),
    last_error = last_error,
    uptime_seconds = uptime,
    features = flags
  )
}

#' Health status as a compact table
#' @keywords internal
health_table <- function(state = NULL) {
  health <- health_status(state)
  rows <- list(
    data.frame(item = "RcmdrShiny", value = health$rcmdrshiny,
               status = "ok", stringsAsFactors = FALSE),
    data.frame(item = "R", value = health$r_version,
               status = "ok", stringsAsFactors = FALSE),
    data.frame(item = "Platform", value = health$platform,
               status = "ok", stringsAsFactors = FALSE),
    data.frame(item = "pandoc",
               value = if (health$pandoc) "available" else "missing",
               status = if (health$pandoc) "ok" else "warning",
               stringsAsFactors = FALSE),
    data.frame(item = "LaTeX",
               value = if (health$latex) "available" else "missing",
               status = if (health$latex) "ok" else "optional",
               stringsAsFactors = FALSE),
    data.frame(item = "Plugins",
               value = sprintf("%d loaded, %d pending",
                               length(health$plugins),
                               length(health$pending_plugins)),
               status = "ok", stringsAsFactors = FALSE),
    data.frame(item = "Help topics", value = as.character(health$help_topics),
               status = "ok", stringsAsFactors = FALSE)
  )
  if (!is.null(health$caches) && nrow(health$caches) > 0L) {
    rows[[length(rows) + 1L]] <- data.frame(
      item = "Caches",
      value = paste(sprintf("%s: %s", health$caches$cache,
                            ifelse(health$caches$ready, "warm", "cold")),
                    collapse = ", "),
      status = "ok", stringsAsFactors = FALSE
    )
  }
  if (!is.null(health$project)) {
    rows[[length(rows) + 1L]] <- data.frame(
      item = "Project",
      value = health$project$title %||% "(none)",
      status = if (isTRUE(health$project$dirty)) "warning" else "ok",
      stringsAsFactors = FALSE
    )
  }
  if (!is.null(health$last_error)) {
    rows[[length(rows) + 1L]] <- data.frame(
      item = "Last error", value = health$last_error, status = "error",
      stringsAsFactors = FALSE
    )
  }
  failures <- health$plugin_failures
  if (!is.null(failures) && nrow(failures) > 0L) {
    rows[[length(rows) + 1L]] <- data.frame(
      item = "Plugin failures",
      value = paste(sprintf("%s: %s", failures$name, failures$message),
                    collapse = "; "),
      status = "error", stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

#' Health card for the Home tab
#' @keywords internal
health_panel_ui <- function(state = NULL) {
  health <- health_status(state)
  table <- health_table(state)
  report <- tryCatch(
    paste(format_diagnostics(diagnostics_report(state)), collapse = "\n"),
    error = function(e) ""
  )

  htmltools::tags$div(
    class = "rcmdr-home-card rcmdr-health",
    htmltools::tags$div(
      class = "d-flex justify-content-between align-items-center mb-1",
      htmltools::tags$h5(class = "mb-0", tr("Health")),
      htmltools::tags$span(
        class = "badge text-bg-success", tr("ready")
      )
    ),
    htmltools::tags$table(
      class = "table table-sm small mb-2",
      htmltools::tags$tbody(
        lapply(seq_len(nrow(table)), function(i) {
          htmltools::tags$tr(
            htmltools::tags$td(table$item[[i]]),
            htmltools::tags$td(class = "text-muted", table$value[[i]]),
            htmltools::tags$td(
              htmltools::tags$span(
                class = paste0("badge text-bg-",
                               if (table$status[[i]] %in% c("ok", "optional")) {
                                 "light"
                               } else if (identical(table$status[[i]], "error")) {
                                 "danger"
                               } else {
                                 "warning"
                               }),
                table$status[[i]]
              )
            )
          )
        })
      )
    ),
    htmltools::tags$div(
      class = "d-flex gap-2 flex-wrap",
      actionButton("health_refresh", tr("Refresh"), class = "btn-sm btn-outline-secondary"),
      actionButton("health_diagnostics", tr("Diagnostics"),
                   class = "btn-sm btn-outline-secondary"),
      htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary",
        `data-rcmdr-copy` = report,
        tr("Copy report")
      )
    )
  )
}
