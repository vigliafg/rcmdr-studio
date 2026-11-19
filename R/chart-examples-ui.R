# Chart example gallery UI ------------------------------------------------

#' Example gallery toolbar and layout
#' @keywords internal
chart_examples_ui <- function() {
  htmltools::tagList(
    toolbar(
      left = htmltools::div(
        class = "rcmdr-toolbar-fields",
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_examples_family", NULL,
            choices = chart_example_families()
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field",
          selectInput(
            "chart_examples_level", NULL,
            choices = chart_example_levels()
          )
        ),
        htmltools::div(
          class = "rcmdr-toolbar-field rcmdr-toolbar-field-wide",
          textInput(
            "chart_examples_query", NULL,
            placeholder = tr("Search examples...")
          )
        )
      ),
      right = uiOutput("chart_examples_count_ui", inline = TRUE),
      label = tr("Examples")
    ),
    note(tr(
      "Examples are curated recipes adapted from the R Graph Gallery. Open one in the builder, then choose the variables for your data."
    )),
    split_pane(
      "chart_examples_layout",
      htmltools::div(
        class = "rcmdr-example-grid-wrap",
        uiOutput("chart_examples_grid")
      ),
      htmltools::div(
        class = "rcmdr-example-detail-wrap",
        uiOutput("chart_example_detail")
      ),
      initial = 0.64, min = 280, min_second = 300
    )
  )
}

#' Example cards
#' @keywords internal
chart_examples_cards <- function(table, selected = NULL) {
  if (is.null(table) || nrow(table) == 0L) {
    return(empty_state(
      tr("No examples match the filters"),
      tr("Try a different family or clear the search."),
      action = action_row(
        tight = TRUE,
        actionButton("chart_examples_clear", tr("Clear filters"),
                     class = "btn-sm btn-outline-secondary")
      )
    ))
  }
  htmltools::div(
    class = "rcmdr-example-grid",
    lapply(seq_len(nrow(table)), function(i) {
      row <- table[i, , drop = FALSE]
      id <- row$id[[1L]]
      is_selected <- identical(as.character(selected %||% ""), id)
      htmltools::tags$button(
        type = "button",
        class = c("rcmdr-example-card",
                  if (is_selected) "active"),
        `data-example` = id,
        `aria-pressed` = if (is_selected) "true" else "false",
        `aria-label` = sprintf(
          tr("Example: %s, %s, %s"),
          row$title[[1L]], row$family_label[[1L]], row$level_label[[1L]]
        ),
        onclick = sprintf(
          "Shiny.setInputValue('chart_example_select', '%s', {priority: 'event'}); return false;",
          id
        ),
        htmltools::tags$img(
          class = "rcmdr-example-thumb",
          src = row$thumbnail[[1L]],
          alt = sprintf(tr("Preview of %s"), row$title[[1L]]),
          width = 640, height = 400, loading = "lazy",
          decoding = "async"
        ),
        htmltools::tags$span(
          class = "rcmdr-example-card-body",
          htmltools::tags$span(class = "rcmdr-example-title",
                               row$title[[1L]]),
          htmltools::tags$span(
            class = "rcmdr-example-meta",
            row$family_label[[1L]],
            htmltools::tags$span(class = "rcmdr-example-sep", "\u00b7",
                                 `aria-hidden` = "true"),
            badge(
              row$level_label[[1L]],
              if (identical(row$level[[1L]], "custom")) "accent" else "neutral"
            )
          )
        )
      )
    })
  )
}

#' Detail panel of an example
#' @keywords internal
chart_example_detail_ui <- function(example) {
  if (is.null(example)) {
    return(empty_state(
      tr("Select an example"),
      tr("Choose a card to see its preview, description and code.")
    ))
  }
  code <- chart_example_code(example)
  htmltools::div(
    class = "rcmdr-example-detail",
    card_head(
      htmltools::tags$h4(example$title, class = "rcmdr-example-detail-title"),
      aside = badge(
        if (identical(example$level, "custom")) tr("Customised") else tr("Basic"),
        if (identical(example$level, "custom")) "accent" else "neutral"
      )
    ),
    htmltools::tags$img(
      class = "rcmdr-example-detail-image",
      src = chart_example_thumbnail(example$id),
      alt = sprintf(tr("Preview of %s"), example$title),
      width = 640, height = 400
    ),
    htmltools::tags$p(class = "rcmdr-example-description",
                      example$description),
    note(sprintf("%s \u00b7 %s", chart_analysis_label(example$family),
                 chart_type(example$type)$label %||% example$type)),
    action_row(
      tight = TRUE,
      actionButton(
        "chart_example_open", tr("Open in builder"),
        class = "btn-sm btn-primary"
      ),
      chart_copy_link(list(code = code), tr("Copy code"))
    ),
    htmltools::tags$p(
      class = "rcmdr-example-source",
      htmltools::tags$a(
        href = example$source_url,
        target = "_blank", rel = "noopener noreferrer",
        tr("Source: R Graph Gallery")
      )
    ),
    htmltools::tags$details(
      class = "rcmdr-example-code",
      htmltools::tags$summary(tr("Code")),
      htmltools::tags$pre(htmltools::tags$code(code))
    )
  )
}

#' Example gallery server
#'
#' The gallery is a browser, not a renderer: opening an example only fills the
#' builder.  It never runs a command and never loads data into the session.
#' @keywords internal
chart_examples_server <- function(input, output, session, state, chart_env,
                                  apply_recipe, chart_revision,
                                  chart_preview_cache_clear) {
  selected <- reactiveVal(NULL)

  example_table <- reactive({
    chart_example_table(
      family = input$chart_examples_family %||% "all",
      level = input$chart_examples_level %||% "all",
      query = input$chart_examples_query %||% ""
    )
  })

  output$chart_examples_count_ui <- renderUI({
    table <- example_table()
    htmltools::tags$span(
      class = "rcmdr-view-count",
      sprintf(tr("%d example(s)"), nrow(table))
    )
  })

  output$chart_examples_grid <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "examples"))
    chart_examples_cards(example_table(), selected())
  })

  output$chart_example_detail <- renderUI({
    req(view_ready(input, "charts"),
        subview_ready(input, "chart_mode", "examples"))
    chart_example_detail_ui(chart_example(selected()))
  })

  observeEvent(input$chart_example_select, {
    id <- input$chart_example_select %||% ""
    if (!nzchar(id) || !id %in% example_table()$id) return()
    selected(id)
  }, ignoreInit = TRUE)

  observeEvent(input$chart_examples_clear, {
    updateSelectInput(session, "chart_examples_family", selected = "all")
    updateSelectInput(session, "chart_examples_level", selected = "all")
    updateTextInput(session, "chart_examples_query", value = "")
  }, ignoreInit = TRUE)

  observeEvent(input$chart_example_open, {
    example <- chart_example(selected())
    if (is.null(example) || !chart_example_available(example)) return()
    spec <- chart_example_spec_for_dataset(example, state)
    apply_recipe(
      spec,
      label = example$title,
      message = if (is.null(active_dataset(state))) {
        tr("Example loaded: import a data set to preview it.")
      } else {
        tr("Example loaded: choose the variables for your data.")
      }
    )
  }, ignoreInit = TRUE)

  invisible(NULL)
}
