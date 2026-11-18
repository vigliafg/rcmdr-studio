# Help server ----------------------------------------------------------------
#
# One function wires the Help tab and the inline dialog help.  Both share the
# registry, the full-text index and the language fallback implemented in
# R/help.R and R/help-index.R.

#' Help tab server
#'
#' @param input,output,session Shiny objects.
#' @param state Application state.
#' @return `NULL`, invisibly.
#' @export
help_server <- function(input, output, session, state) {
  selected <- shiny::reactiveVal(NULL)
  recent <- shiny::reactiveVal(character())
  filter <- shiny::reactiveVal(NULL)
  current_topic <- shiny::reactiveVal(NULL)
  dialog_help <- shiny::reactiveVal(NULL)
  pending_example <- shiny::reactiveVal(NULL)

  language_token <- function() {
    if (is.function(state$language_revision)) state$language_revision() else NULL
  }

  remember <- function(id) {
    ids <- unique(c(id, recent()))
    recent(utils::head(ids, 5L))
  }

  state$help_show <- function(id, switch_tab = TRUE) {
    topic <- help_topic(id, help_language())
    if (is.null(topic)) return(invisible(FALSE))
    selected(topic$id)
    current_topic(topic)
    filter(NULL)
    remember(topic$id)
    if (isTRUE(switch_tab)) state$show_tab(tr("Help"))
    invisible(TRUE)
  }

  state$help_show_dialog <- function(spec) {
    topic <- help_topic_for_dialog(spec, help_language())
    if (is.null(topic)) return(invisible(FALSE))
    dialog_help(topic)
    invisible(TRUE)
  }

  state$help_reset_dialog <- function() {
    dialog_help(NULL)
    invisible(NULL)
  }

  state$help_topic_open <- function() {
    topic <- current_topic()
    if (is.null(topic)) NULL else topic$id
  }

  output$help_context <- shiny::renderUI({
    language_token()
    if (is.null(state$current_dialog)) return(NULL)
    spec <- get_dialog_spec(state$current_dialog)
    if (is.null(spec)) return(NULL)
    topic <- help_topic_for_dialog(spec, help_language())
    if (is.null(topic)) return(NULL)
    shiny::actionButton(
      "help_current_dialog",
      sprintf(tr("Help on this window: %s"), spec$title),
      class = "btn-sm btn-outline-secondary"
    )
  })

  output$help_categories <- shiny::renderUI({
    language_token()
    index <- help_index()
    latest <- filter()
    htmltools::tagList(
      lapply(seq_len(nrow(index)), function(i) {
        category <- index[i, , drop = FALSE]
        htmltools::tags$div(
          class = if (identical(category$id, latest)) {
            "rcmdr-help-category active"
          } else {
            "rcmdr-help-category"
          },
          help_category_ui(category)
        )
      })
    )
  })

  output$help_recent <- shiny::renderUI({
    language_token()
    ids <- recent()
    if (length(ids) == 0L) return(NULL)
    htmltools::tagList(
      htmltools::tags$h6(tr("Recent")),
      htmltools::tags$ul(
        lapply(ids, function(id) help_topic_link_ui(id))
      )
    )
  })

  help_type_filter <- function() {
    value <- input$help_type %||% "all"
    if (!nzchar(value)) "all" else value
  }

  help_package_filter <- function() {
    value <- input$help_package %||% "all"
    if (!nzchar(value)) "all" else value
  }

  filters_active <- function() {
    !is.null(filter()) ||
      !identical(help_type_filter(), "all") ||
      !identical(help_package_filter(), "all")
  }

  output$help_results <- shiny::renderUI({
    language_token()
    category <- filter()
    query <- input$help_query %||% ""
    type <- help_type_filter()
    package <- help_package_filter()

    if (nzchar(trimws(query))) {
      results <- help_search(
        query, limit = 20L, language = help_language(),
        category = category, type = type, package = package
      )
      if (nrow(results) == 0L) {
        return(htmltools::tags$p(
          class = "text-muted",
          tr("No help topic matches the search.")
        ))
      }
      return(htmltools::tagList(
        help_result_count(nrow(results)),
        lapply(seq_len(nrow(results)), function(i) {
          help_result_ui(results[i, , drop = FALSE])
        })
      ))
    }

    if (!is.null(category) || filters_active()) {
      catalog <- help_catalog(
        category = category, language = help_language(),
        type = type, package = package
      )
      if (nrow(catalog) == 0L) {
        return(htmltools::tags$p(
          class = "text-muted",
          tr("No help topic matches the filters.")
        ))
      }
      title <- if (is.null(category)) {
        tr("Filtered topics")
      } else {
        categories <- help_index()
        match <- match(category, categories$id)
        label <- if (is.na(match)) help_title_case(category) else
          categories$title[[match]]
        tr(label)
      }
      return(htmltools::tagList(
        htmltools::tags$h5(title),
        help_result_count(nrow(catalog)),
        htmltools::tags$ul(
          class = "rcmdr-help-list",
          lapply(seq_len(nrow(catalog)), function(i) {
            htmltools::tags$li(help_topic_link(catalog$id[[i]],
                                               catalog$title[[i]]))
          })
        )
      ))
    }

    help_welcome_ui(state)
  })

  output$help_topic <- shiny::renderUI({
    language_token()
    topic <- current_topic()
    if (is.null(topic)) return(help_welcome_ui(state))
    topic <- help_topic(topic$id, help_language()) %||% topic
    help_topic_panel_ui(topic, state)
  })

  shiny::observeEvent(input$help_open, {
    state$help_show(input$help_open, switch_tab = FALSE)
  })

  shiny::observeEvent(input$help_category, {
    filter(input$help_category)
    selected(NULL)
    current_topic(NULL)
  })

  shiny::observeEvent(input$help_clear_filters, {
    filter(NULL)
    shiny::updateTextInput(session, "help_query", value = "")
    shiny::updateSelectInput(session, "help_type", selected = "all")
    shinyWidgets::updateVirtualSelect(
      "help_package", selected = "all", session = session
    )
  })

  shiny::observeEvent(input$help_current_dialog, {
    spec <- get_dialog_spec(state$current_dialog %||% "")
    if (!is.null(spec)) state$help_show_dialog(spec)
  })

  shiny::observeEvent(input$help_r_reference, {
    topic <- current_topic()
    if (is.null(topic) || length(topic$commands) == 0L) return()
    package <- if (length(topic$packages) > 0L) topic$packages[[1L]] else NULL
    if (is.null(help_topic_text(topic$commands[[1L]], package_name = package))) {
      shiny::showNotification(
        sprintf(tr("No R reference found for '%s'."), topic$commands[[1L]]),
        type = "message", duration = 5
      )
    } else {
      show_help_modal(topic$commands[[1L]], package)
    }
  })

  shiny::observeEvent(input$help_open_center, {
    topic <- current_topic()
    if (!is.null(topic)) state$help_show(topic$id)
  })

  shiny::observeEvent(input$help_open_dialog, {
    id <- input$help_open_dialog
    if (is.null(id) || !nzchar(id)) return()
    if (!is.function(state$open_dialog)) return()
    tryCatch(state$open_dialog(id), error = function(e) {
      shiny::showNotification(conditionMessage(e), type = "error", duration = 5)
    })
  })

  shiny::observeEvent(input$help_report_issue, {
    report <- tryCatch(format_diagnostics(), error = function(e) {
      paste(tr("Diagnostics unavailable:"), conditionMessage(e))
    })
    shiny::showModal(shiny::modalDialog(
      title = tr("Report an issue"),
      htmltools::tagList(
        htmltools::tags$p(tr(
          "Copy this report into the issue together with the step that failed. It contains versions and help counts, never your data."
        )),
        htmltools::tags$pre(class = "rcmdr-help-text",
                            paste(report, collapse = "\n"))
      ),
      size = "l", easyClose = TRUE,
      footer = shiny::modalButton(tr("Close"))
    ))
  })

  # -- examples -------------------------------------------------------------

  help_example_run <- function(topic_id, index) {
    topic <- help_topic(topic_id, help_language())
    if (is.null(topic)) return(invisible(NULL))
    examples <- help_topic_examples(topic)
    example <- examples[[as.integer(index)]]
    if (is.null(example) || !isTRUE(example$runnable)) return(invisible(NULL))
    pending_example(list(topic = topic$id, index = as.integer(index),
                         code = example$code))
    needs_dataset <- help_example_needs_dataset(state, example$code)
    choices <- help_example_dataset_choices(state)
    selected <- active_dataset(state)
    if (is.null(selected) && length(choices) > 0L) selected <- choices[[1L]]
    shiny::showModal(shiny::modalDialog(
      title = tr("Run help example"),
      htmltools::tagList(
        htmltools::tags$pre(class = "rcmdr-help-example-code", example$code),
        if (needs_dataset) {
          shiny::selectInput(
            "help_example_dataset", tr("Data set"),
            choices = choices,
            selected = selected %||% "",
            width = "100%"
          )
        },
        htmltools::tags$p(
          class = "small text-muted",
          tr("The command is logged in the history exactly as shown.")
        )
      ),
      easyClose = TRUE,
      footer = htmltools::tagList(
        shiny::modalButton(tr("Cancel")),
        shiny::actionButton("help_example_confirm", tr("Run"),
                            class = "btn-primary")
      )
    ))
    invisible(NULL)
  }

  shiny::observeEvent(input$help_example_run, {
    value <- input$help_example_run
    if (is.null(value)) return()
    topic_id <- value$topic %||% NULL
    index <- value$index %||% 1L
    if (is.null(topic_id)) return()
    help_example_run(topic_id, index)
  })

  shiny::observeEvent(input$help_example_confirm, {
    pending <- pending_example()
    if (is.null(pending)) return()
    dataset <- input$help_example_dataset %||% NULL
    prepared <- help_example_prepare_code(state, pending$code, dataset = dataset)
    if (!is.null(prepared$error)) {
      shiny::showNotification(prepared$error, type = "error", duration = 6)
      return()
    }
    shiny::removeModal()
    pending_example(NULL)
    result <- tryCatch(
      run_command(state, prepared$code, source = "help"),
      error = function(e) list(status = "error", error = conditionMessage(e))
    )
    if (identical(result$status, "error")) {
      shiny::showNotification(
        result$error %||% tr("The example produced an error."),
        type = "error", duration = 8
      )
    } else {
      shiny::showNotification(
        tr("Example executed. It is now in the history."),
        type = "message", duration = 4
      )
    }
    if (is.function(state$notify)) state$notify()
    state$show_tab(tr("Output"))
  })

  shiny::observeEvent(input$help_example_insert, {
    code <- input$help_example_insert
    if (is.null(code) || !nzchar(code)) return()
    insert_commands_into_script(state, code)
    state$show_tab(tr("Script"))
    shiny::showNotification(tr("Example inserted into the script."),
                            type = "message", duration = 3)
  })

  # -- inline help inside dialogs -------------------------------------------

  output$dialog_help_panel <- shiny::renderUI({
    language_token()
    topic <- dialog_help()
    if (is.null(topic)) return(NULL)
    topic <- help_topic(topic$id, help_language()) %||% topic
    help_dialog_panel_ui(topic)
  })

  shiny::observeEvent(input$dialog_help, {
    spec <- get_dialog_spec(state$current_dialog %||% "")
    if (is.null(spec)) return()
    if (!isTRUE(state$help_show_dialog(spec))) {
      shiny::showNotification(
        sprintf(tr("No help topic for '%s'."), spec$title),
        type = "warning", duration = 5
      )
    }
  })

  shiny::observeEvent(input$dialog_help_close, {
    dialog_help(NULL)
  })

  shiny::observeEvent(input$dialog_help_center, {
    topic <- dialog_help()
    if (is.null(topic)) return()
    dialog_help(NULL)
    shiny::removeModal()
    state$current_dialog <- NULL
    state$help_show(topic$id)
  })

  shiny::observeEvent(input$dialog_help_reference, {
    topic <- dialog_help()
    if (is.null(topic) || length(topic$commands) == 0L) return()
    package <- if (length(topic$packages) > 0L) topic$packages[[1L]] else NULL
    help_text <- help_topic_text(topic$commands[[1L]], package_name = package)
    if (is.null(help_text)) {
      shiny::showNotification(
        sprintf(tr("No R reference found for '%s'."), topic$commands[[1L]]),
        type = "message", duration = 5
      )
    } else {
      shiny::showModal(shiny::modalDialog(
        title = sprintf(tr("Help: %s"), topic$commands[[1L]]),
        htmltools::tags$pre(class = "rcmdr-help-text", help_text),
        size = "l", easyClose = TRUE,
        footer = shiny::modalButton(tr("Close"))
      ))
    }
  })

  invisible(NULL)
}

# -- example helpers ---------------------------------------------------------

#' Data sets that a help example can use
#'
#' @param state Application state.
#' @return A named character vector; names are labels, values are object names.
#' @keywords internal
help_example_dataset_choices <- function(state) {
  objects <- tryCatch(ls(state$env), error = function(e) character())
  frames <- Filter(function(name) {
    is.data.frame(get(name, envir = state$env, inherits = FALSE))
  }, objects)
  if (length(frames) == 0L) return(stats::setNames(character(), character()))
  stats::setNames(frames, frames)
}

help_example_needs_dataset <- function(state, code) {
  if (grepl("{dataset}", code, fixed = TRUE)) return(TRUE)
  grepl("\\bDataset\\b", code) &&
    !exists("Dataset", envir = state$env, inherits = FALSE)
}

#' Prepare an example for execution
#'
#' Replaces the `{dataset}` placeholder and the conventional `Dataset` name
#' with the selected data set, but only when the object does not already exist.
#'
#' @param state Application state.
#' @param code Example source.
#' @param dataset Data set chosen by the user, or `NULL`.
#' @return A list with `code` and `error` (or `NULL`).
#' @keywords internal
help_example_prepare_code <- function(state, code, dataset = NULL) {
  code <- paste(code, collapse = "\n")
  dataset <- dataset %||% active_dataset(state)
  needs <- help_example_needs_dataset(state, code)
  if (needs) {
    if (is.null(dataset) || !nzchar(dataset)) {
      return(list(code = code,
                  error = tr("This example needs a data set. Import one or select it in the dialog.")))
    }
    if (!exists(dataset, envir = state$env, inherits = FALSE)) {
      return(list(code = code,
                  error = sprintf(tr("Data set '%s' does not exist."), dataset)))
    }
  }
  if (grepl("{dataset}", code, fixed = TRUE)) {
    code <- gsub("{dataset}", dataset, code, fixed = TRUE)
  }
  if (!is.null(dataset) && help_example_needs_dataset(state, code)) {
    code <- gsub("\\bDataset\\b", dataset, code)
  }
  list(code = code, error = NULL)
}
