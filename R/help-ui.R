# Help user interface --------------------------------------------------------
#
# The Help tab is a small browser: a search box with filters, a category list, a
# result list and a topic pane.  All content is rendered on the server, so the
# same code works offline and for plugin topics.

#' Help centre UI
#'
#' @param filter_choices Optional list of filter choices returned by
#'   [help_filter_choices()].
#' @return A `shiny.tag.list` with the Help tab.
#' @export
help_center_ui <- function(filter_choices = NULL) {
  filter_choices <- filter_choices %||% help_filter_choices()
  htmltools::tagList(
    htmltools::div(
      class = "rcmdr-help-search",
      htmltools::tags$label(
        class = "visually-hidden", `for` = "help_query",
        tr("Search help")
      ),
      shiny::textInput(
        "help_query", NULL,
        placeholder = tr("Search help topics..."),
        width = "100%"
      ),
      htmltools::div(
        class = "rcmdr-help-filters",
        shiny::selectInput(
          "help_type", tr("Type"), choices = filter_choices$types,
          width = "170px"
        ),
        # The package list grows with every plugin, so it is a searchable
        # picker; the type list stays a native select because it is short.
        picker_input(
          "help_package", tr("Source"), filter_choices$packages,
          selected = "all", width = "190px"
        ),
        shiny::actionButton("help_clear_filters", tr("Clear filters"),
                            class = "btn-sm btn-outline-secondary")
      ),
      htmltools::div(
        class = "rcmdr-help-context",
        uiOutput("help_context")
      )
    ),
    htmltools::div(
      class = "rcmdr-help-layout",
      htmltools::div(
        class = "rcmdr-help-aside",
        htmltools::div(
          class = "rcmdr-help-sidebar", role = "navigation",
          `aria-label` = tr("Help categories"),
          htmltools::tags$h6(tr("Categories")),
          uiOutput("help_categories"),
          uiOutput("help_recent")
        )
      ),
      htmltools::div(
        class = "rcmdr-help-content",
        htmltools::div(
          `aria-live` = "polite", class = "rcmdr-help-results",
          uiOutput("help_results")
        ),
        htmltools::div(
          class = "rcmdr-help-topic", id = "help_topic_pane",
          tabindex = "-1",
          uiOutput("help_topic")
        )
      )
    )
  )
}

help_language <- function() {
  language <- tryCatch(current_language(), error = function(e) "en")
  if (!nzchar(language)) "en" else language
}

help_escape_id <- function(x) {
  gsub("[^A-Za-z0-9_.:-]", "", as.character(x))
}

help_topic_link <- function(id, label) {
  htmltools::tags$a(
    href = "#",
    class = "rcmdr-help-link",
    `data-help-topic` = help_escape_id(id),
    label
  )
}

help_topic_link_ui <- function(id, label = NULL) {
  topic <- help_topic(id, help_language())
  if (is.null(topic)) return(NULL)
  label <- label %||% topic$title
  htmltools::tags$li(help_topic_link(topic$id, label))
}

# Open an existing dialog from a help topic.  The click is handled by the same
# delegated listener that opens help links; no dialog is opened at render time.
help_dialog_link_ui <- function(dialog_id, label = NULL) {
  if (is.null(dialog_id) || !nzchar(dialog_id)) return(NULL)
  label <- label %||% dialog_id
  htmltools::tags$a(
    href = "#",
    class = "rcmdr-help-dialog-link",
    `data-help-dialog` = dialog_id,
    label
  )
}

help_welcome_ui <- function(state = NULL) {
  htmltools::tagList(
    htmltools::tags$h3(tr("Help centre")),
    htmltools::tags$p(tr(
      "Search the topics or pick a category. Every dialog also has a Help button."
    )),
    htmltools::tags$div(
      class = "rcmdr-help-quick",
      htmltools::tags$h5(tr("Start here")),
      htmltools::tags$ul(
        htmltools::tags$li(help_topic_link("getting-started",
                                           tr("Your first analysis"))),
        htmltools::tags$li(help_topic_link("data-import", tr("Importing data"))),
        htmltools::tags$li(help_topic_link("glossary", tr("Glossary"))),
        htmltools::tags$li(help_topic_link("keyboard-shortcuts",
                                           tr("Keyboard shortcuts"))),
        htmltools::tags$li(help_topic_link("help-center",
                                           tr("Using the help centre")))
      )
    )
  )
}

#' Count line above the Help results
#'
#' It is a live region of its own so a new search announces how many topics it
#' found without repeating the whole list.
#' @keywords internal
help_result_count <- function(n) {
  htmltools::tags$p(
    class = "text-muted small rcmdr-help-count",
    role = "status", `aria-live` = "polite",
    sprintf(tr("%d topic(s) found"), as.integer(n))
  )
}

help_result_ui <- function(result) {  id <- help_escape_id(result$id)
  package <- result$package %||% NA_character_
  type <- result$type %||% "task"
  snippet <- result$snippet_html %||% htmltools::htmlEscape(result$snippet %||% "")
  htmltools::tags$a(
    href = "#",
    class = "rcmdr-help-result",
    onclick = sprintf(
      "Shiny.setInputValue('help_open', '%s', {priority: 'event'}); return false;",
      id
    ),
    htmltools::tags$span(class = "rcmdr-help-result-title", result$title),
    htmltools::tags$span(class = "rcmdr-help-result-meta",
                         htmltools::tags$span(class = "badge text-bg-light", type),
                         if (!is.na(package) && nzchar(package)) {
                           htmltools::tags$span(class = "badge text-bg-light", package)
                         },
                         htmltools::tags$span(class = "rcmdr-help-result-category",
                                              result$category)),
    if (nzchar(snippet)) {
      htmltools::tags$p(class = "rcmdr-help-result-snippet",
                        htmltools::HTML(snippet))
    }
  )
}

help_category_ui <- function(category) {
  htmltools::tags$a(
    href = "#",
    class = "rcmdr-help-category",
    onclick = sprintf(
      "Shiny.setInputValue('help_category', '%s', {priority: 'event'}); return false;",
      help_escape_id(category$id)
    ),
    htmltools::tags$span(tr(category$title)),
    htmltools::tags$span(class = "badge text-bg-light", category$count)
  )
}

help_toc_ui <- function(topic) {
  toc <- help_toc(topic$body)
  toc <- toc[toc$level >= 2L, , drop = FALSE]
  if (nrow(toc) == 0L) return(NULL)
  htmltools::tags$nav(
    class = "rcmdr-help-toc",
    `aria-label` = tr("On this page"),
    htmltools::tags$h5(tr("On this page")),
    htmltools::tags$ul(
      lapply(seq_len(nrow(toc)), function(i) {
        htmltools::tags$li(
          class = paste0("rcmdr-help-toc-level-", toc$level[[i]]),
          htmltools::tags$a(href = paste0("#", toc$anchor[[i]]), toc$title[[i]])
        )
      })
    )
  )
}

help_example_ui <- function(topic, example) {
  code <- example$code %||% ""
  if (!nzchar(code)) return(NULL)
  index <- example$index %||% 1L
  id <- help_escape_id(topic$id)
  htmltools::tags$div(
    class = "rcmdr-help-example",
    if (!is.null(example$title) && nzchar(example$title)) {
      htmltools::tags$h5(example$title)
    },
    htmltools::tags$pre(class = "rcmdr-help-example-code", code),
    htmltools::tags$div(
      class = "rcmdr-help-example-actions",
      if (isTRUE(example$runnable)) {
        htmltools::tags$button(
          type = "button", class = "btn btn-sm btn-primary",
          `data-help-example` = id,
          `data-help-example-index` = index,
          tr("Run")
        )
      },
      htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary",
        `data-rcmdr-copy` = code,
        tr("Copy")
      ),
      htmltools::tags$button(
        type = "button", class = "btn btn-sm btn-outline-secondary",
        `data-help-example-insert` = code,
        tr("Insert into script")
      )
    )
  )
}

help_examples_ui <- function(topic) {
  examples <- help_topic_examples(topic)
  if (length(examples) == 0L) return(NULL)
  htmltools::tags$section(
    class = "rcmdr-help-examples",
    htmltools::tags$h5(tr("Examples")),
    lapply(examples, function(example) help_example_ui(topic, example))
  )
}

help_dialogs_ui <- function(topic) {
  dialogs <- topic$dialogs %||% character()
  if (length(dialogs) == 0L) return(NULL)
  htmltools::tags$section(
    class = "rcmdr-help-dialogs",
    htmltools::tags$h5(tr("Related dialogs")),
    htmltools::tags$ul(
      lapply(dialogs, function(id) {
        spec <- tryCatch(get_dialog_spec(id), error = function(e) NULL)
        label <- if (is.null(spec)) id else spec$title
        htmltools::tags$li(help_dialog_link_ui(id, label))
      })
    )
  )
}

help_commands_ui <- function(topic) {
  commands <- topic$commands %||% character()
  if (length(commands) == 0L) return(NULL)
  htmltools::tags$section(
    class = "rcmdr-help-commands",
    htmltools::tags$h5(tr("Commands cited")),
    htmltools::tags$ul(
      lapply(commands, function(command) {
        htmltools::tags$li(
          htmltools::tags$code(command),
          htmltools::tags$button(
            type = "button", class = "btn btn-sm btn-link",
            `data-rcmdr-copy` = command,
            tr("Copy")
          )
        )
      })
    )
  )
}

help_topic_footer_ui <- function(topic) {
  reference <- length(topic$commands) > 0L
  htmltools::div(
    class = "rcmdr-help-footer",
    if (reference) {
      shiny::actionButton(
        "help_r_reference", tr("R reference"),
        class = "btn-sm btn-outline-secondary"
      )
    },
    shiny::actionButton(
      "help_report_issue", tr("Report an issue"),
      class = "btn-sm btn-outline-secondary"
    ),
    htmltools::tags$button(
      type = "button", class = "btn btn-sm btn-outline-secondary",
      `data-rcmdr-copy` = paste0("topic:", topic$id),
      tr("Copy link")
    ),
    shiny::actionButton(
      "help_open_center", tr("Open in help centre"),
      class = "btn-sm btn-outline-primary"
    )
  )
}

help_topic_panel_ui <- function(topic, state = NULL) {
  htmltools::tagList(
    help_toc_ui(topic),
    htmltools::div(
      class = "rcmdr-help-body",
      htmltools::HTML(help_topic_html_from_record(topic))
    ),
    help_examples_ui(topic),
    help_dialogs_ui(topic),
    help_commands_ui(topic),
    if (length(topic$related) > 0L) {
      related <- Filter(Negate(is.null),
                        lapply(topic$related, help_topic_link_ui))
      if (length(related) > 0L) {
        htmltools::div(
          class = "rcmdr-help-related",
          htmltools::tags$h5(tr("Related topics")),
          htmltools::tags$ul(related)
        )
      }
    },
    help_topic_footer_ui(topic)
  )
}

# Panel shown inside a dialog when the Help button is pressed.  Keeping the
# help inside the dialog avoids stacking modals and preserves the fields the
# user has already filled in.
help_dialog_panel_ui <- function(topic) {
  htmltools::div(
    class = "rcmdr-help-inline",
    card_head(
      htmltools::tags$h5(topic$title),
      shiny::actionButton(
        "dialog_help_close", tr("Close help"),
        class = "btn-sm btn-outline-secondary"
      )
    ),
    help_toc_ui(topic),
    htmltools::div(
      class = "rcmdr-help-body",
      htmltools::HTML(help_topic_html_from_record(topic))
    ),
    help_dialogs_ui(topic),
    htmltools::div(
      class = "rcmdr-help-footer",
      if (length(topic$commands) > 0L) {
        shiny::actionButton(
          "dialog_help_reference", tr("R reference"),
          class = "btn-sm btn-outline-secondary"
        )
      },
      shiny::actionButton(
        "dialog_help_center", tr("Open in help centre"),
        class = "btn-sm btn-outline-primary"
      )
    )
  )
}
