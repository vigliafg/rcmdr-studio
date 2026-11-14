# Guided workflows -----------------------------------------------------------
#
# A workflow is an ordered list of steps that orchestrates the existing
# dialogs and direct commands.  It never adds a statistical procedure and it
# never validates a step itself: the dialog or command remains the source of
# truth.  Each completed step contributes the commands it produced to a draft
# report section.

#' Workflow step
#'
#' @param id Step identifier unique inside the workflow.
#' @param title Step title shown in the UI.
#' @param dialog Optional dialog id (for example `"linearModel"`).
#' @param command Optional direct command id (for example `"countMissing"`).
#' @param action Optional session action handled by [workflow_action_run()].
#' @param memory Optional list, or function of the state returning a list, used
#'   to pre-fill the dialog.
#' @param optional Whether the step can be skipped.
#' @param requires Optional package or plugin name shown in the reason when the
#'   step is unavailable.
#' @keywords internal
workflow_step <- function(id, title, dialog = NULL, command = NULL,
                          action = NULL, memory = list(), optional = TRUE,
                          requires = NULL) {
  list(
    id = id,
    title = title,
    dialog = dialog,
    command = command,
    action = action,
    memory = memory,
    optional = isTRUE(optional),
    requires = requires
  )
}

#' Workflow specification
#' @keywords internal
workflow_spec <- function(id, title, description, steps,
                          report_section = NULL) {
  structure(
    list(
      id = id,
      title = title,
      description = description,
      steps = steps,
      report_section = report_section %||% paste0("## ", title)
    ),
    class = "RcmdrShinyWorkflow"
  )
}

first_numeric <- function(state, n = 1L) {
  vars <- numeric_variables(state)
  if (length(vars) == 0L) return(NULL)
  utils::head(vars, n)
}

first_factor <- function(state) {
  vars <- factor_variables(state)
  if (length(vars) == 0L) return(NULL)
  vars[[1L]]
}

#' Built-in workflows
#' @keywords internal
workflow_registry_builtin <- function() {
  list(
    describe = workflow_spec(
      id = "describe",
      title = tr("Describe the data"),
      description = tr("Summary statistics, missing values and the main distributions."),
      steps = list(
        workflow_step(
          "summary", tr("Numerical summaries"),
          dialog = "numericalSummaries",
          memory = function(state) list(
            x = first_numeric(state, 3L),
            mean = TRUE, sd = TRUE, quantiles = TRUE
          ),
          optional = FALSE
        ),
        workflow_step(
          "missing", tr("Missing values"),
          command = "countMissing"
        ),
        workflow_step(
          "histogram", tr("Histogram"),
          dialog = "Histogram",
          memory = function(state) list(variable = first_numeric(state))
        ),
        workflow_step(
          "boxplot", tr("Boxplot"),
          dialog = "boxPlot",
          memory = function(state) list(variables = first_numeric(state, 3L))
        )
      ),
      report_section = "## Description of the data"
    ),
    compare = workflow_spec(
      id = "compare",
      title = tr("Compare groups"),
      description = tr("Summaries by group, a group test and a boxplot."),
      steps = list(
        workflow_step(
          "summary", tr("Summaries by group"),
          dialog = "numericalSummaries",
          memory = function(state) list(
            x = first_numeric(state), groups = first_factor(state),
            mean = TRUE, sd = TRUE
          ),
          optional = FALSE
        ),
        workflow_step(
          "ttest", tr("Two-sample t-test"),
          dialog = "independentSamplesTTest",
          memory = function(state) list(
            group = first_factor(state), response = first_numeric(state)
          )
        ),
        workflow_step(
          "anova", tr("One-way ANOVA"),
          dialog = "oneWayAnova",
          memory = function(state) list(
            group = first_factor(state), response = first_numeric(state)
          )
        ),
        workflow_step(
          "boxplot", tr("Boxplot by group"),
          dialog = "boxPlot",
          memory = function(state) list(
            variables = first_numeric(state),
            response = first_numeric(state),
            group = first_factor(state)
          )
        )
      ),
      report_section = "## Comparison of groups"
    ),
    linear = workflow_spec(
      id = "linear",
      title = tr("Linear model"),
      description = tr("Fit, summarise, diagnose and plot the effects of a linear model."),
      steps = list(
        workflow_step(
          "fit", tr("Fit the model"),
          dialog = "linearModel",
          memory = function(state) {
            response <- first_numeric(state)
            predictors <- setdiff(numeric_variables(state), response)
            list(
              model_name = paste0("LinearModel.", (state$model_number %||% 0L) + 1L),
              lhs = response,
              rhs = paste(utils::head(predictors, 3L), collapse = " + ")
            )
          },
          optional = FALSE
        ),
        workflow_step(
          "summary", tr("Summarise the model"),
          command = "summarizeModel"
        ),
        workflow_step(
          "diagnostics", tr("Diagnostic plots"),
          command = "plotModel"
        ),
        workflow_step(
          "effects", tr("Effect plots"),
          dialog = "effectPlots",
          memory = function(state) list(model = state$active_model)
        )
      ),
      report_section = "## Linear model"
    ),
    report = workflow_spec(
      id = "report",
      title = tr("Prepare the report"),
      description = tr("Create an R Markdown report, insert the data profile and the latest plot, then knit."),
      steps = list(
        workflow_step(
          "document", tr("New report document"),
          dialog = "newRmd",
          memory = list(title = "RcmdrShiny report"),
          optional = FALSE
        ),
        workflow_step(
          "profile", tr("Data profile"),
          action = "report_profile"
        ),
        workflow_step(
          "plot", tr("Latest plot"),
          action = "report_plot"
        ),
        workflow_step(
          "knit", tr("Knit the report"),
          action = "report_knit"
        )
      ),
      report_section = "## Report preparation"
    ),
    survival = workflow_spec(
      id = "survival",
      title = tr("Survival analysis"),
      description = tr("Kaplan-Meier curve, log-rank test and Cox model from the survival plugin."),
      steps = list(
        workflow_step(
          "km", tr("Kaplan-Meier curve"),
          dialog = "Survfit",
          requires = "RcmdrShinyPlugin.survival",
          optional = FALSE
        ),
        workflow_step(
          "logrank", tr("Log-rank test"),
          dialog = "Survdiff",
          requires = "RcmdrShinyPlugin.survival"
        ),
        workflow_step(
          "cox", tr("Cox model"),
          dialog = "CoxModel",
          requires = "RcmdrShinyPlugin.survival"
        )
      ),
      report_section = "## Survival analysis"
    )
  )
}

#' Find a workflow
#' @keywords internal
workflow_find <- function(id) {
  workflow_registry()[[id]] %||% NULL
}

#' State of a workflow step
#' @keywords internal
workflow_step_available <- function(state, step) {
  if (!is.null(step$dialog)) {
    available <- tryCatch(step$dialog %in% dialog_ids(),
                          error = function(e) FALSE)
    if (available) {
      spec <- tryCatch(get_dialog_spec(step$dialog), error = function(e) NULL)
      available <- !is.null(spec)
    }
    reason <- if (available) "" else sprintf(
      tr("Dialog '%s' is not available."), step$dialog
    )
    if (!available && !is.null(step$requires)) {
      reason <- sprintf(tr("Load the %s plugin to use this step."),
                        step$requires)
    }
    return(list(ok = available, reason = reason))
  }
  if (!is.null(step$command)) {
    available <- tryCatch(step$command %in% names(direct_commands()),
                          error = function(e) FALSE)
    if (available && step$command %in% c("summarizeModel", "plotModel") &&
        is.null(active_model(state))) {
      return(list(ok = FALSE, reason = tr("Fit a model first.")))
    }
    if (available && identical(step$command, "countMissing") &&
        is.null(active_dataset(state))) {
      return(list(ok = FALSE, reason = tr("Select a data set first.")))
    }
    return(list(
      ok = available,
      reason = if (available) "" else sprintf(
        tr("Command '%s' is not available."), step$command
      )
    ))
  }
  if (!is.null(step$action)) {
    return(list(ok = TRUE, reason = ""))
  }
  list(ok = FALSE, reason = tr("The step has no action."))
}

#' Active workflow instance
#' @keywords internal
workflow_active <- function(state) state$workflow %||% NULL

#' Start a workflow
#' @keywords internal
workflow_start <- function(state, id) {
  spec <- workflow_find(id)
  if (is.null(spec)) return(list(ok = FALSE, error = tr("Unknown workflow.")))
  statuses <- stats::setNames(rep("pending", length(spec$steps)),
                              vapply(spec$steps, `[[`, character(1), "id"))
  state$workflow_counter <- as.integer(state$workflow_counter %||% 0L) + 1L
  state$workflow <- list(
    instance = state$workflow_counter,
    id = spec$id,
    spec = spec,
    statuses = statuses,
    current = 1L,
    commands = list(),
    history_ids = character(),
    started = Sys.time(),
    completed = FALSE
  )
  state_touch(state)
  list(ok = TRUE, workflow = state$workflow)
}

#' Current step of the active workflow
#' @keywords internal
workflow_current_step <- function(state) {
  active <- workflow_active(state)
  if (is.null(active)) return(NULL)
  index <- active$current %||% 1L
  if (index < 1L || index > length(active$spec$steps)) return(NULL)
  list(
    index = index,
    step = active$spec$steps[[index]],
    status = active$statuses[[index]] %||% "pending"
  )
}

workflow_first_pending <- function(active) {
  statuses <- active$statuses
  pending <- which(statuses == "pending")
  if (length(pending) > 0L) return(pending[[1L]])
  NA_integer_
}

workflow_advance <- function(state) {
  active <- state$workflow
  if (is.null(active)) return(invisible(NULL))
  index <- workflow_first_pending(active)
  active$completed <- is.na(index)
  if (!is.na(index)) active$current <- index
  state$workflow <- active
  state_touch(state)
  invisible(active)
}

#' Open or run a workflow step
#'
#' Dialog steps are returned to the caller, which opens the dialog through the
#' standard runtime.  Direct commands and session actions run immediately.
#' @keywords internal
workflow_step_open <- function(state, step_id = NULL) {
  active <- workflow_active(state)
  if (is.null(active)) return(list(ok = FALSE, error = tr("No active workflow.")))
  index <- if (is.null(step_id)) active$current else {
    match(step_id, vapply(active$spec$steps, `[[`, character(1), "id"))
  }
  if (is.na(index) || index < 1L || index > length(active$spec$steps)) {
    return(list(ok = FALSE, error = tr("Unknown workflow step.")))
  }
  step <- active$spec$steps[[index]]
  availability <- workflow_step_available(state, step)
  if (!isTRUE(availability$ok)) {
    return(list(ok = FALSE, error = availability$reason, step = step))
  }
  active$current <- index
  state$workflow <- active

  if (!is.null(step$dialog)) {
    memory <- if (is.function(step$memory)) {
      tryCatch(step$memory(state), error = function(e) list())
    } else {
      step$memory %||% list()
    }
    return(list(ok = TRUE, dialog = step$dialog, memory = memory,
                step = step, index = index, ran = FALSE))
  }
  if (!is.null(step$command)) {
    result <- workflow_run_command(state, step$command)
    if (isTRUE(result$ok)) {
      workflow_mark_index(state, index, commands = result$commands %||% character())
    }
    return(c(result, list(step = step, index = index, ran = TRUE)))
  }
  if (!is.null(step$action)) {
    result <- workflow_action_run(state, step$action)
    if (isTRUE(result$ok)) workflow_mark_index(state, index, commands = character())
    return(c(result, list(step = step, index = index, ran = TRUE)))
  }
  list(ok = FALSE, error = tr("The step has no action."))
}

#' Run a direct command inside a workflow
#' @keywords internal
workflow_run_command <- function(state, command) {
  action <- direct_commands()[[command]]
  if (is.null(action)) {
    return(list(ok = FALSE, error = sprintf(
      tr("Command '%s' is not available."), command
    )))
  }
  old_source <- state$execution_source
  state$execution_source <- "workflow"
  on.exit(state$execution_source <- old_source, add = TRUE)
  before <- length(state$log %||% character())
  result <- tryCatch(action(state), error = function(e) e)
  if (inherits(result, "error")) {
    return(list(ok = FALSE, error = conditionMessage(result)))
  }
  log <- state$log %||% character()
  commands <- if (length(log) > before) log[seq.int(before + 1L, length(log))] else
    character()
  list(ok = TRUE, commands = commands)
}

#' Run a session action used by a workflow
#' @keywords internal
workflow_action_run <- function(state, action) {
  result <- tryCatch(
    switch(
      action,
      report_profile = {
        report_insert_data_profile(state)
        list(ok = TRUE, message = tr("Data profile inserted."))
      },
      report_plot = {
        report_insert_plot(state)
        list(ok = TRUE, message = tr("Plot inserted."))
      },
      report_knit = {
        document_knit(state)
        list(ok = TRUE, message = tr("Report knitted."))
      },
      report_show = {
        if (is.function(state$show_tab)) state$show_tab(tr("Report"))
        list(ok = TRUE)
      },
      list(ok = FALSE, error = sprintf(tr("Unknown action: %s"), action))
    ),
    error = function(e) list(ok = FALSE, error = conditionMessage(e))
  )
  result
}

workflow_mark_index <- function(state, index, commands = character(),
                                history_ids = character()) {
  active <- state$workflow
  if (is.null(active)) return(invisible(FALSE))
  active$statuses[[index]] <- "done"
  if (length(commands) > 0L) {
    active$commands[[active$spec$steps[[index]]$id]] <- commands
  } else {
    active$commands[[active$spec$steps[[index]]$id]] <- character()
  }
  active$history_ids <- unique(c(active$history_ids, history_ids))
  active$current <- index
  state$workflow <- active
  workflow_advance(state)
  invisible(TRUE)
}

#' Mark the workflow step that a dialog just completed
#' @keywords internal
workflow_mark_step <- function(state, dialog_id, result = NULL,
                               history_ids = character()) {
  active <- workflow_active(state)
  if (is.null(active) || is.null(dialog_id)) return(invisible(FALSE))
  dialogs <- vapply(active$spec$steps, function(step) step$dialog %||% "",
                    character(1))
  index <- match(dialog_id, dialogs)
  if (is.na(index)) return(invisible(FALSE))
  if (identical(active$statuses[[index]], "done")) return(invisible(FALSE))
  commands <- result$commands %||% character()
  if (length(commands) == 0L && !is.null(result$script) &&
      nzchar(result$script)) {
    commands <- result$script
  }
  workflow_mark_index(state, index, commands = commands,
                      history_ids = history_ids)
  invisible(TRUE)
}

#' Mark the current step as skipped
#' @keywords internal
workflow_skip_step <- function(state, step_id = NULL) {
  active <- workflow_active(state)
  if (is.null(active)) return(list(ok = FALSE, error = tr("No active workflow.")))
  index <- if (is.null(step_id)) active$current else {
    match(step_id, vapply(active$spec$steps, `[[`, character(1), "id"))
  }
  if (is.na(index) || index < 1L || index > length(active$spec$steps)) {
    return(list(ok = FALSE, error = tr("Unknown workflow step.")))
  }
  step <- active$spec$steps[[index]]
  if (!isTRUE(step$optional)) {
    return(list(ok = FALSE, error = tr("This step is required.")))
  }
  active$statuses[[index]] <- "skipped"
  active$current <- index
  state$workflow <- active
  workflow_advance(state)
  list(ok = TRUE)
}

#' Move back to the previous step
#' @keywords internal
workflow_back <- function(state) {
  active <- workflow_active(state)
  if (is.null(active)) return(list(ok = FALSE, error = tr("No active workflow.")))
  index <- max(1L, (active$current %||% 1L) - 1L)
  active$current <- index
  state$workflow <- active
  state_touch(state)
  list(ok = TRUE, index = index)
}

#' Cancel the active workflow
#' @keywords internal
workflow_cancel <- function(state) {
  if (is.null(state$workflow)) return(invisible(FALSE))
  state$workflow <- NULL
  state_touch(state)
  invisible(TRUE)
}

#' Progress table for the active workflow
#' @keywords internal
workflow_progress <- function(state) {
  active <- workflow_active(state)
  if (is.null(active)) {
    return(data.frame(
      index = integer(), id = character(), title = character(),
      status = character(), optional = logical(), available = logical(),
      reason = character(), current = logical(), stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(seq_along(active$spec$steps), function(i) {
    step <- active$spec$steps[[i]]
    availability <- workflow_step_available(state, step)
    data.frame(
      index = i,
      id = step$id,
      title = step$title,
      status = active$statuses[[i]] %||% "pending",
      optional = isTRUE(step$optional),
      available = isTRUE(availability$ok),
      reason = availability$reason %||% "",
      current = identical(i, active$current),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Draft report section for the active workflow
#' @keywords internal
workflow_report_section <- function(state) {
  active <- workflow_active(state)
  if (is.null(active)) return("")
  lines <- c(active$spec$report_section %||% paste0("## ", active$spec$title), "")
  done <- FALSE
  for (step in active$spec$steps) {
    status <- active$statuses[[step$id]] %||% "pending"
    if (!identical(status, "done")) next
    done <- TRUE
    commands <- active$commands[[step$id]] %||% character()
    lines <- c(lines, paste0("### ", step$title), "")
    if (length(commands) > 0L) {
      lines <- c(
        lines,
        sprintf("```{r workflow-%s-%s}", active$id, step$id),
        commands,
        "```",
        ""
      )
    }
  }
  if (!done) return("")
  paste(lines, collapse = "\n")
}

#' Insert the workflow draft into the report
#' @keywords internal
workflow_insert_report <- function(state) {
  section <- workflow_report_section(state)
  if (!nzchar(section)) {
    return(list(ok = FALSE, error = tr("Complete at least one step first.")))
  }
  if (!document_mode(state) %in% c("rmd", "rnw")) {
    title <- if (!is.null(state$workflow)) state$workflow$spec$title else
      tr("Workflow report")
    document_new(state, "rmd", title)
  }
  report_insert_block(state, section)
  if (is.function(state$sync_document)) state$sync_document()
  list(ok = TRUE, section = section)
}

# UI -------------------------------------------------------------------------

workflow_status_pill <- function(status) {
  switch(
    status,
    done = status_pill(tr("Done"), "ok"),
    skipped = status_pill(tr("Skipped"), "muted"),
    blocked = status_pill(tr("Blocked"), "warning"),
    status_pill(tr("Pending"), "muted")
  )
}

workflow_button <- function(action, step = NULL, label, class = "btn-outline-secondary") {
  payload <- if (is.null(step)) {
    sprintf("{action: '%s'}", action)
  } else {
    sprintf("{action: '%s', step: '%s'}", action, step)
  }
  htmltools::tags$button(
    type = "button", class = paste("btn btn-sm", class),
    onclick = sprintf(
      "Shiny.setInputValue('workflow_action', %s, {priority: 'event'}); return false;",
      payload
    ),
    label
  )
}

#' Workflow cards and active step list
#' @keywords internal
workflow_panel_ui <- function(state) {
  if (!isTRUE(feature_enabled(state, "workflows"))) return(NULL)
  active <- workflow_active(state)
  if (is.null(active)) {
    workflows <- workflow_registry()
    cards <- lapply(workflows, function(workflow) {
      htmltools::tags$div(
        class = "rcmdr-workflow-card",
        htmltools::tags$h6(workflow$title),
        htmltools::tags$p(class = "small text-muted mb-2",
                          workflow$description),
        htmltools::tags$p(
          class = "small text-muted mb-2",
          sprintf(tr("%d steps"), length(workflow$steps))
        ),
        workflow_button("start", workflow$id, tr("Start"), "btn-primary")
      )
    })
    return(htmltools::tags$div(
      id = "workflow_panel",
      class = "rcmdr-workflow-panel",
      htmltools::tags$div(
        class = "d-flex justify-content-between align-items-center mb-2",
        htmltools::tags$h5(tr("Guided workflows")),
        htmltools::tags$span(class = "small text-muted",
                             tr("Every step uses an existing dialog or command."))
      ),
      htmltools::tags$div(class = "rcmdr-workflow-grid", cards)
    ))
  }

  progress <- workflow_progress(state)
  rows <- lapply(seq_len(nrow(progress)), function(i) {
    row <- progress[i, , drop = FALSE]
    status <- row$status[[1L]]
    if (!isTRUE(row$available[[1L]]) && identical(status, "pending")) {
      status <- "blocked"
    }
    htmltools::tags$div(
      class = paste("rcmdr-workflow-step",
                    if (isTRUE(row$current[[1L]])) "current"),
      htmltools::tags$div(
        class = "d-flex justify-content-between align-items-center gap-2",
        htmltools::tags$span(
          htmltools::tags$strong(sprintf("%d. %s", row$index[[1L]],
                                         row$title[[1L]])),
          if (isTRUE(row$optional[[1L]])) {
            htmltools::tags$span(class = "small text-muted",
                                 tr(" (optional)"))
          }
        ),
        htmltools::tags$div(
          class = "d-flex gap-1 align-items-center",
          workflow_status_pill(status)
        )
      ),
      if (!isTRUE(row$available[[1L]])) {
        htmltools::tags$p(class = "small text-warning mb-1", row$reason[[1L]])
      },
      htmltools::tags$div(
        class = "d-flex gap-1 flex-wrap mt-1",
        if (isTRUE(row$available[[1L]]) &&
            !identical(row$status[[1L]], "done")) {
          workflow_button("open", row$id[[1L]],
                          if (is.null(active$spec$steps[[row$index[[1L]]]]$dialog)) {
                            tr("Run")
                          } else {
                            tr("Open step")
                          },
                          "btn-outline-primary")
        },
        if (isTRUE(row$optional[[1L]]) &&
            !identical(row$status[[1L]], "done") &&
            !identical(row$status[[1L]], "skipped")) {
          workflow_button("skip", row$id[[1L]], tr("Skip"))
        }
      )
    )
  })

  section <- workflow_report_section(state)
  htmltools::tags$div(
    id = "workflow_panel",
    class = "rcmdr-workflow-panel active",
    studio_breadcrumb(c(tr("Workflows"), active$spec$title)),
    htmltools::tags$div(
      class = "d-flex justify-content-between align-items-center mb-2",
      htmltools::tags$h5(active$spec$title),
      htmltools::tags$span(class = "small text-muted",
                           active$spec$description)
    ),
    htmltools::tags$div(class = "rcmdr-workflow-steps", rows),
    htmltools::tags$div(
      class = "d-flex gap-1 flex-wrap mt-2",
      workflow_button("back", NULL, tr("Back")),
      workflow_button("cancel", NULL, tr("Cancel"), "btn-outline-danger"),
      if (nzchar(section)) {
        workflow_button("report_section", NULL, tr("Show report section"),
                        "btn-outline-primary")
      },
      if (nzchar(section)) {
        workflow_button("report_insert", NULL, tr("Insert into report"),
                        "btn-primary")
      }
    ),
    if (nzchar(section)) {
      htmltools::tags$details(
        class = "rcmdr-workflow-draft",
        htmltools::tags$summary(tr("Draft report section")),
        htmltools::tags$pre(section)
      )
    }
  )
}


# Plugin workflows extend the built-in registry.  A plugin cannot replace a
# built-in workflow by id; it can only add a new one.  This keeps the documented
# onboarding paths stable.
workflow_registry <- function() {
  registry <- workflow_registry_builtin()
  extras <- tryCatch(plugin_workflows(), error = function(e) list())
  for (id in names(extras)) {
    if (!id %in% names(registry)) registry[[id]] <- extras[[id]]
  }
  registry
}
