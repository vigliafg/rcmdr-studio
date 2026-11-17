# Onboarding: tour and first-run checklist -----------------------------------
#
# The tour is a small set of steps over the existing interface.  It never runs
# commands and never changes the statistical state; each step only switches tab
# and highlights an element.  The checklist is derived from the session (data,
# history, documents and plots) so that it cannot drift from what the user has
# actually done.

tour_storage_key <- function() "rcmdr-tour-dismissed"

#' Steps of the guided tour
#'
#' @return A list of steps with `id`, `title`, `body`, `tab`, `target` and
#'   `help_topic`.
#' @export
tour_steps <- function() {
  list(
    list(
      id = "data",
      title = tr("Start with your data"),
      body = tr("Import a data set, inspect its columns in the Data Studio and use the inspector to choose the next analysis."),
      tab = "Data",
      target = "#main-content",
      help_topic = "data-studio"
    ),
    list(
      id = "charts",
      title = tr("Build a chart"),
      body = tr("Chart Studio turns a visual specification into reproducible ggplot2 code. The preview is isolated and the gallery keeps every chart."),
      tab = "Charts",
      target = "#main-content",
      help_topic = "chart-studio"
    ),
    list(
      id = "report",
      title = tr("Write a report"),
      body = tr("Report Studio collects commands, output and plots in an R Markdown document that can be knitted and downloaded."),
      tab = "Report",
      target = "#main-content",
      help_topic = "report-studio"
    ),
    list(
      id = "palette",
      title = tr("Find anything with the palette"),
      body = tr("Press Ctrl+K to search menus, dialogs, help topics, data and history. Favourites and recents stay at the top of the sidebar."),
      tab = "Home",
      target = "#palette_open",
      help_topic = "navigation-workflows"
    )
  )
}

#' One tour step
#'
#' @param index Step number, starting at 1.
#' @return A step list, or `NULL` when the index is out of range.
#' @export
tour_step <- function(index = 1L) {
  steps <- tour_steps()
  index <- as.integer(index %||% 1L)
  if (is.na(index) || index < 1L || index > length(steps)) return(NULL)
  steps[[index]]
}

#' Tour modal for a step
#'
#' @param step Step returned by [tour_step()].
#' @param index Current step number.
#' @param total Total number of steps.
#' @return A Shiny modal dialog.
#' @export
tour_modal <- function(step, index, total) {
  last <- index >= total
  shiny::modalDialog(
    title = sprintf(tr("Tour: %s"), step$title),
    htmltools::tagList(
      htmltools::tags$p(class = "text-muted small mb-2",
                        sprintf(tr("Step %d of %d"), index, total)),
      htmltools::tags$p(step$body),
      htmltools::tags$p(
        class = "small",
        htmltools::tags$a(
          href = "#", `data-help-topic` = step$help_topic,
          tr("Open the related help topic")
        )
      )
    ),
    size = "m",
    easyClose = FALSE,
    footer = htmltools::tagList(
      shiny::actionButton("tour_dismiss", tr("Don't show again"),
                          class = "btn-sm btn-outline-secondary"),
      shiny::actionButton("tour_skip", tr("Skip"),
                          class = "btn-sm btn-outline-secondary"),
      if (index > 1L) {
        shiny::actionButton("tour_back", tr("Back"),
                            class = "btn-sm btn-outline-secondary")
      },
      shiny::actionButton("tour_next", if (last) tr("Done") else tr("Next"),
                          class = "btn-primary")
    )
  )
}

# -- checklist ---------------------------------------------------------------

onboarding_history_commands <- function(state) {
  entries <- state$history %||% list()
  if (length(entries) == 0L) return(character())
  vapply(entries, function(entry) entry$command %||% "", character(1))
}

onboarding_did_import <- function(state) {
  length(state$datasets %||% list()) > 0L || !is.null(active_dataset(state))
}

onboarding_did_summary <- function(state) {
  commands <- onboarding_history_commands(state)
  if (length(commands) == 0L) return(FALSE)
  any(grepl("\\b(summary|numSummary|summ)\\s*\\(", commands))
}

onboarding_did_chart <- function(state) {
  if (length(state$plots %||% list()) > 0L) return(TRUE)
  if (!is.null(state$chart_last_spec)) return(TRUE)
  commands <- onboarding_history_commands(state)
  any(grepl("\\b(plot|hist|boxplot|barplot|ggplot|xyplot|bwplot)\\s*\\(",
            commands))
}

onboarding_did_report <- function(state) {
  documents <- state$documents %||% list()
  if (any(vapply(documents, function(doc) {
    !identical(doc$mode %||% "r", "r")
  }, logical(1)))) {
    return(TRUE)
  }
  commands <- onboarding_history_commands(state)
  any(grepl("\\b(newRmd|newRnw|render|knit)\\s*\\(", commands))
}

onboarding_did_project <- function(state) {
  isTRUE(state$project_saved) && feature_enabled(state, "project")
}

#' First-run checklist
#'
#' @param state Application state.
#' @return A list of records with `id`, `label`, `description`, `done`,
#'   `available` and `action`.
#' @export
onboarding_checklist <- function(state) {
  list(
    list(
      id = "import",
      label = tr("Import a data set"),
      description = tr("Open the import dialog or use the Data Studio."),
      done = onboarding_did_import(state),
      available = TRUE,
      action = "import"
    ),
    list(
      id = "summary",
      label = tr("Run a summary"),
      description = tr("Numerical summaries are the quickest first analysis."),
      done = onboarding_did_summary(state),
      available = TRUE,
      action = "summary"
    ),
    list(
      id = "chart",
      label = tr("Create a chart"),
      description = tr("Build a chart and keep it in the gallery."),
      done = onboarding_did_chart(state),
      available = TRUE,
      action = "chart"
    ),
    list(
      id = "report",
      label = tr("Create a report"),
      description = tr("Start an R Markdown document and knit it."),
      done = onboarding_did_report(state),
      available = TRUE,
      action = "report"
    ),
    list(
      id = "project",
      label = tr("Save a project"),
      description = tr("Save data, documents and plots in a project."),
      done = onboarding_did_project(state),
      available = feature_enabled(state, "project"),
      action = "project"
    )
  )
}

#' Checklist progress
#'
#' @param state Application state.
#' @return A list with `done`, `total` and `percent`.
#' @export
onboarding_progress <- function(state) {
  checks <- onboarding_checklist(state)
  available <- Filter(function(check) isTRUE(check$available), checks)
  total <- length(available)
  done <- sum(vapply(available, function(check) isTRUE(check$done), logical(1)))
  list(
    done = done,
    total = total,
    percent = if (total == 0L) 0L else as.integer(round(100 * done / total))
  )
}

#' Checklist card for the Home tab
#'
#' @param state Application state.
#' @return A Shiny tag.
#' @export
onboarding_checklist_ui <- function(state) {
  checks <- onboarding_checklist(state)
  progress <- onboarding_progress(state)
  htmltools::tags$div(
    class = "rcmdr-home-card rcmdr-checklist",
    card_head(
      htmltools::tags$h5(tr("First steps")),
      badge(sprintf(tr("%d of %d"), progress$done, progress$total), "neutral")
    ),
    htmltools::tags$div(
      class = "progress rcmdr-checklist-progress",
      htmltools::tags$div(
        class = "progress-bar",
        role = "progressbar",
        style = sprintf("width: %d%%", progress$percent),
        `aria-valuenow` = progress$percent,
        `aria-valuemin` = 0, `aria-valuemax` = 100
      )
    ),
    htmltools::tags$ul(
      class = "rcmdr-checklist-list",
      lapply(checks, function(check) {
        htmltools::tags$li(
          class = paste0(
            "rcmdr-checklist-item",
            if (isTRUE(check$done)) " done" else "",
            if (!isTRUE(check$available)) " unavailable" else ""
          ),
          htmltools::tags$span(
            class = "rcmdr-checklist-mark",
            if (isTRUE(check$done)) "\u2713" else "\u25cb"
          ),
          htmltools::tags$span(
            class = "rcmdr-checklist-label",
            htmltools::tags$strong(check$label),
            note(check$description, inline = TRUE)
          ),
          if (!isTRUE(check$done) && isTRUE(check$available)) {
            shiny::actionButton(
              paste0("home_check_", check$id),
              tr("Start"),
              class = "btn-sm btn-outline-secondary rcmdr-checklist-action"
            )
          }
        )
      })
    )
  )
}
