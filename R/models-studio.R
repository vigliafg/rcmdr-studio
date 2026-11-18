# Models Studio --------------------------------------------------------------
#
# A registry and dashboard for the models that already exist in the session.
# It recognises the classes created by the dialogs and the console, shows the
# usual fit metadata, and runs existing commands for diagnostics.  It never
# adds a statistical procedure.

#' Model classes recognised by the registry
#'
#' Extends the menu activation list with the mixed-model wrappers and a few
#' regression classes that the console can create.
#' @keywords internal
model_registry_classes <- function() {
  unique(c(
    model_classes,
    "merMod", "rlm", "clm", "vglm", "betareg", "lme", "gls"
  ))
}

#' Is an object a model?
#' @keywords internal
model_is_object <- function(object) {
  if (is.null(object)) return(FALSE)
  inherits(object, model_registry_classes())
}

model_short <- function(text, width = 90L) {
  text <- paste(text %||% "", collapse = " ")
  text <- gsub("\\s+", " ", trimws(text))
  if (nchar(text) > width) paste0(substr(text, 1L, width - 1L), "\u2026") else text
}

model_number_or_na <- function(expression) {
  value <- tryCatch(suppressWarnings(expression), error = function(e) NA_real_)
  if (is.null(value) || length(value) != 1L) NA_real_ else as.numeric(value)
}

#' Metadata for one model
#' @keywords internal
model_metadata <- function(state, name, object = NULL) {
  if (is.null(object)) {
    if (!exists(name, envir = state$env, inherits = FALSE)) return(NULL)
    object <- get(name, envir = state$env, inherits = FALSE)
  }
  if (!model_is_object(object)) return(NULL)
  formula <- tryCatch(
    model_short(paste(deparse(stats::formula(object)), collapse = " ")),
    error = function(e) ""
  )
  data_name <- tryCatch({
    call_data <- object$call$data
    if (is.null(call_data)) "" else model_short(paste(deparse(call_data),
                                                      collapse = " "))
  }, error = function(e) "")
  family <- tryCatch({
    if (!is.null(object$family$family)) object$family$family else ""
  }, error = function(e) "")
  n <- tryCatch(stats::nobs(object), error = function(e) NA_integer_)
  aic <- model_number_or_na(stats::AIC(object))
  bic <- model_number_or_na(stats::BIC(object))
  r2 <- if (inherits(object, "lm") && !inherits(object, "glm")) {
    model_number_or_na(summary(object)$r.squared)
  } else {
    NA_real_
  }
  list(
    name = name,
    class = paste(class(object), collapse = ", "),
    formula = formula,
    family = family,
    data = data_name,
    n = as.integer(n %||% NA_integer_),
    aic = aic,
    bic = bic,
    r2 = r2,
    active = identical(name, state$active_model)
  )
}

#' Registry of the fitted models
#'
#' @return A data frame with `name`, `class`, `formula`, `family`, `data`,
#'   `n`, `aic`, `bic`, `r2` and `active`, sorted by AIC.
#' @keywords internal
model_registry <- function(state) {
  objects <- ls(envir = state$env)
  rows <- lapply(objects, function(name) {
    object <- tryCatch(get(name, envir = state$env, inherits = FALSE),
                       error = function(e) NULL)
    if (!model_is_object(object)) return(NULL)
    meta <- model_metadata(state, name, object)
    if (is.null(meta)) return(NULL)
    data.frame(
      name = meta$name, class = meta$class, formula = meta$formula,
      family = meta$family, data = meta$data, n = meta$n,
      aic = meta$aic, bic = meta$bic, r2 = meta$r2,
      active = meta$active, stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(data.frame(
      name = character(), class = character(), formula = character(),
      family = character(), data = character(), n = integer(),
      aic = numeric(), bic = numeric(), r2 = numeric(), active = logical(),
      stringsAsFactors = FALSE
    ))
  }
  table <- do.call(rbind, rows)
  order <- order(is.na(table$aic), table$aic, table$name)
  table[order, , drop = FALSE]
}

#' Find one model in the registry
#' @keywords internal
model_find <- function(state, name) {
  table <- model_registry(state)
  if (nrow(table) == 0L || is.null(name)) return(NULL)
  index <- match(name, table$name)
  if (is.na(index)) NULL else table[index, , drop = FALSE]
}

#' History entry that created a model
#' @keywords internal
model_history_entry <- function(state, name) {
  history <- state$history %||% list()
  if (length(history) == 0L) return(NULL)
  prefix <- paste0(name, " <-")
  for (entry in history) {
    command <- trimws(entry$command %||% "")
    if (startsWith(command, prefix) && !is.null(entry$dialog_id) &&
        nzchar(entry$dialog_id)) {
      return(entry)
    }
  }
  NULL
}

#' Default dialog for a model class
#' @keywords internal
model_default_dialog <- function(object) {
  if (inherits(object, "glmerMod")) return("generalizedLinearMixedModel")
  if (inherits(object, "lmerMod") || inherits(object, "merMod")) {
    return("linearMixedModel")
  }
  if (inherits(object, "glm") || inherits(object, "polr") ||
      inherits(object, "multinom")) {
    return("generalizedLinearModel")
  }
  if (inherits(object, "lm") || inherits(object, "aov") ||
      inherits(object, "rlm") || inherits(object, "nls") ||
      inherits(object, "loess")) {
    return("linearModel")
  }
  NULL
}

#' Reopen the dialog that fitted a model
#' @keywords internal
model_reopen_dialog <- function(state, name) {
  if (is.null(name) || !exists(name, envir = state$env, inherits = FALSE)) {
    return(invisible(FALSE))
  }
  if (!is.function(state$open_dialog)) {
    return(invisible(FALSE))
  }
  entry <- model_history_entry(state, name)
  if (!is.null(entry) && !is.null(get_dialog_spec(entry$dialog_id))) {
    set_dialog_memory(state, entry$dialog_id, entry$dialog_memory %||% list())
    state$open_dialog(entry$dialog_id)
    return(invisible(TRUE))
  }
  object <- get(name, envir = state$env, inherits = FALSE)
  dialog <- model_default_dialog(object)
  if (!is.null(dialog) && !is.null(get_dialog_spec(dialog))) {
    set_dialog_memory(state, dialog, list(model = name, model_name = name))
    state$open_dialog(dialog)
    return(invisible(TRUE))
  }
  if (!is.null(state$session)) {
    showNotification(
      tr("The dialog for this model is not available. Use the command instead."),
      type = "message", duration = 6
    )
  }
  invisible(FALSE)
}

#' Run an action on a model
#'
#' Every printing action executes an existing command through the command
#' engine.  `active` and `reopen` are session operations.
#' @keywords internal
model_action <- function(state, name, action = "summary") {
  if (is.null(name) || !exists(name, envir = state$env, inherits = FALSE)) {
    return(list(ok = FALSE, message = tr("The model is not available.")))
  }
  object <- get(name, envir = state$env, inherits = FALSE)
  if (!model_is_object(object)) {
    return(list(ok = FALSE, message = tr("The object is not a model.")))
  }
  state$model_selection <- name
  switch(
    action,
    select = list(ok = TRUE),
    active = {
      active_model(state, name)
      list(ok = TRUE)
    },
    summary = {
      run_command(state, cmd_summarize_model(name), source = "model",
                  dialog_id = NULL)
      list(ok = TRUE)
    },
    anova = {
      run_command(state, cmd_anova_table(name), source = "model",
                  plot = FALSE)
      list(ok = TRUE)
    },
    effects = {
      run_command(state, paste0("print(effects::allEffects(", name, "))"),
                  source = "model", plot = FALSE)
      list(ok = TRUE)
    },
    diagnostics = {
      for (command in cmd_plot_model(name)) {
        run_command(state, command, source = "model")
      }
      list(ok = TRUE)
    },
    influence = {
      run_command(state, cmd_influence_index(name), source = "model")
      list(ok = TRUE)
    },
    vif = {
      for (command in cmd_vif(name)) {
        run_command(state, command, source = "model", plot = FALSE)
      }
      list(ok = TRUE)
    },
    aic = {
      run_command(state, cmd_aic(name), source = "model", plot = FALSE)
      list(ok = TRUE)
    },
    bic = {
      run_command(state, cmd_bic(name), source = "model", plot = FALSE)
      list(ok = TRUE)
    },
    stepwise = {
      run_command(state, cmd_stepwise(name), source = "model", plot = FALSE)
      list(ok = TRUE)
    },
    export = {
      if (!is.function(state$open_dialog)) {
        return(list(ok = FALSE, message = "Dialogs are not available."))
      }
      open_dialog_memory(state, "modelExport", list(model = name))
      list(ok = TRUE)
    },
    reopen = {
      model_reopen_dialog(state, name)
      list(ok = TRUE)
    },
    remove = {
      run_command(state, paste0("rm(", name, ")"), source = "model",
                  plot = FALSE)
      if (identical(state$active_model, name)) state$active_model <- NULL
      if (identical(state$model_selection, name)) state$model_selection <- NULL
      list(ok = TRUE)
    },
    list(ok = FALSE, message = sprintf("Unknown action: %s", action))
  )
}

#' Model export dialog
#' @keywords internal
model_export_dialog <- function() {
  id <- "modelExport"
  ns <- function(x) paste0(id, "_", x)

  dialog_spec(
    id = id, title = tr("Export model"), help_topic = "workbench",
    preview = TRUE,
    ui = function(state, memory) {
      table <- model_registry(state)
      choices <- if (nrow(table) == 0L) {
        stats::setNames("", tr("<none>"))
      } else {
        stats::setNames(table$name, table$name)
      }
      selected <- memory$model %||% state$model_selection %||%
        (if (nrow(table) > 0L) table$name[[1L]] else "")
      htmltools::tagList(
        selectInput(ns("model"), tr("Model"), choices = choices,
                    selected = selected, width = "100%"),
        entry_input(ns("path"), tr("Output file:"),
                    memory$path %||% file.path(getwd(), "model-summary.txt")),
        selectInput(
          ns("what"), tr("Content"),
          choices = c("Coefficients" = "coefficients",
                      "Summary" = "summary", "AIC and BIC" = "fit"),
          selected = memory$what %||% "coefficients", width = "100%"
        ),
        help_text(tr("The file is written by a reproducible R command."))
      )
    },
    on_ok = function(input, state) {
      model <- input[[ns("model")]] %||% ""
      path <- trim_blanks(input[[ns("path")]] %||% "")
      what <- input[[ns("what")]] %||% "coefficients"
      if (!nzchar(model) || !exists(model, envir = state$env, inherits = FALSE)) {
        return(list(error = tr("Choose an existing model.")))
      }
      if (!nzchar(path)) return(list(error = tr("Enter an output file.")))
      if (!dir.exists(dirname(path))) {
        return(list(error = sprintf(tr("Directory not found: %s"),
                                    dirname(path))))
      }
      quoted <- encodeString(path, quote = "\"")
      command <- switch(
        what,
        coefficients = sprintf(
          "write.csv(as.data.frame(summary(%s)$coefficients), file = %s, row.names = TRUE)",
          model, quoted
        ),
        summary = sprintf(
          "writeLines(capture.output(summary(%s)), con = %s)", model, quoted
        ),
        fit = sprintf(
          "writeLines(c('AIC: ', AIC(%s), 'BIC: ', BIC(%s)), con = %s)",
          model, model, quoted
        )
      )
      list(
        commands = command,
        memory = list(model = model, path = path, what = what),
        message = sprintf(tr("Exporting %s."), model)
      )
    }
  )
}

# UI -------------------------------------------------------------------------

model_action_button <- function(name, action, label, class = "btn-outline-secondary") {
  htmltools::tags$button(
    type = "button", class = paste("btn btn-sm", class),
    onclick = sprintf(
      "Shiny.setInputValue('model_action', {name: '%s', action: '%s'}, {priority: 'event'});",
      name, action
    ),
    label
  )
}

model_row_color <- function(active) if (isTRUE(active)) "table-active" else NULL

#' Models dashboard
#' @keywords internal
models_dashboard_ui <- function(state) {
  table <- model_registry(state)
  if (nrow(table) == 0L) {
    return(empty_state(
      tr("No models yet"),
      tr("Fit a model from the Models menu or the console and it will appear here.")
    ))
  }
  selected <- state$model_selection %||% state$active_model
  if (!is.null(selected) && !selected %in% table$name) selected <- NULL
  best <- if (any(!is.na(table$aic))) min(table$aic, na.rm = TRUE) else NA_real_
  rows <- lapply(seq_len(nrow(table)), function(i) {
    row <- table[i, , drop = FALSE]
    delta <- if (is.na(row$aic[[1L]]) || is.na(best)) {
      ""
    } else {
      sprintf("+%.1f", row$aic[[1L]] - best)
    }
    htmltools::tags$tr(
      class = model_row_color(row$active[[1L]]),
      htmltools::tags$td(htmltools::tags$code(row$name[[1L]])),
      htmltools::tags$td(row$class[[1L]]),
      htmltools::tags$td(row$formula[[1L]]),
      htmltools::tags$td(if (is.na(row$n[[1L]])) "" else row$n[[1L]]),
      htmltools::tags$td(if (is.na(row$aic[[1L]])) "" else sprintf("%.1f", row$aic[[1L]])),
      htmltools::tags$td(delta),
      htmltools::tags$td(if (is.na(row$bic[[1L]])) "" else sprintf("%.1f", row$bic[[1L]])),
      htmltools::tags$td(if (is.na(row$r2[[1L]])) "" else sprintf("%.3f", row$r2[[1L]])),
      htmltools::tags$td(model_action_button(row$name[[1L]], "select", tr("Actions")))
    )
  })
  htmltools::tagList(
    table_scroll(
      label = tr("Model comparison"),
      htmltools::tags$table(
        class = "table table-sm rcmdr-models-table",
        htmltools::tags$thead(htmltools::tags$tr(
          htmltools::tags$th(tr("Model")), htmltools::tags$th(tr("Class")),
          htmltools::tags$th(tr("Formula")), htmltools::tags$th(tr("n")),
          htmltools::tags$th("AIC"), htmltools::tags$th(tr("Delta AIC")),
          htmltools::tags$th("BIC"), htmltools::tags$th(tr("R squared")),
          htmltools::tags$th(tr("Actions"))
        )),
        htmltools::tags$tbody(rows)
      )
    ),
    if (!is.null(selected)) {
      model_actions_ui(state, selected)
    } else {
      htmltools::tags$p(
        class = "text-muted small",
        tr("Choose Actions on a model to open its command panel.")
      )
    }
  )
}

#' Action panel for the selected model
#' @keywords internal
model_actions_ui <- function(state, name) {
  row <- model_find(state, name)
  if (is.null(row)) return(NULL)
  htmltools::tags$div(
    class = "rcmdr-section-card",
    htmltools::tags$h6(sprintf(tr("Model %s"), name)),
    htmltools::tags$p(class = "small text-muted mb-2", row$formula[[1L]]),
    htmltools::div(
      class = "d-flex gap-1 flex-wrap mb-2",
      model_action_button(name, "summary", tr("Summary")),
      model_action_button(name, "anova", tr("ANOVA")),
      model_action_button(name, "effects", tr("Effects")),
      model_action_button(name, "diagnostics", tr("Diagnostics")),
      model_action_button(name, "influence", tr("Influence")),
      model_action_button(name, "vif", tr("VIF")),
      model_action_button(name, "aic", "AIC"),
      model_action_button(name, "bic", "BIC"),
      model_action_button(name, "stepwise", tr("Stepwise")),
      model_action_button(name, "export", tr("Export")),
      model_action_button(name, "reopen", tr("Reopen dialog")),
      model_action_button(name, "remove", tr("Remove"), "btn-outline-danger")
    ),
    if (!isTRUE(row$active[[1L]])) {
      model_action_button(name, "active", tr("Set active"), "btn-outline-primary")
    } else {
      status_pill(tr("Active model"), "ok")
    }
  )
}
